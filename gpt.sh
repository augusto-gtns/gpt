#!/bin/bash

cd $(dirname "$0") || exit # navigate to absolute path

source .env # default env config

[[ -f .env.custom ]] && source .env.custom # custom config

[[ "$OPENAI_API_KEY" == "" ]] && printf "\n please set OPENAI_API_KEY env var \n" && exit

### FUNCTIONS ### 

should_retry(){
	try_again=""
	while [[ "$try_again" != "y" && "$try_again" != "n" ]]; do
		read -e -p "🔸no answer receiveid, try again? (y/n): " try_again
	done
	
	[[ "$try_again" == "n" ]] && exit 0
}

prompt_once(){
	prompt="$@"

	payload='{
		"model": "'$OPENAI_COMPL_MODEL'",
		"temperature": '$OPENAI_COMPL_TEMPERATURE',
		"max_tokens": '$OPENAI_COMPL_MAX_TOKENS',
		"prompt": "'$prompt'"
	}'
	
	echo -e "$(date) payload: \n $payload \n" > log.txt

	while [ true ]; do
		response=$(curl https://api.openai.com/v1/completions \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $OPENAI_API_KEY" \
			-d "$payload" -k -L -s \
			--connect-timeout 10 --max-time 60 --retry 2 --retry-delay 0 --retry-max-time 120)
		
		[[ "$response" != "" ]] && break
		should_retry
	done

	echo -e "$(date) response: \n $response \n" >> log.txt

	answer=$(jq -r '.choices[].text' <<< "$response")	
	printf "$answer \n"
}

start_chat(){
	role="$@"
	[[ "$role" == "" ]] && role=$OPENAI_CHAT_ROLE
	printf "\n🔹assistant role: $role\n\n"

	payload='{
		"model": "'$OPENAI_CHAT_MODEL'",
		"temperature": '$OPENAI_CHAT_TEMPERATURE',
		"messages": [{"role": "assistant", "content": "'$role'"}]
	}'

	echo "" > log.txt
	
	while [ true ]; do

		while [ "$prompt" == "" ]; do
			read -e -p "🔹you: " prompt
		done

		user_message='{"role": "user", "content": "'$prompt'"}'

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $user_message")

		echo -e "$(date) payload: \n $payload \n" >> log.txt
		
		while [ true ]; do
			response=$(curl https://api.openai.com/v1/chat/completions \
				-H "Content-Type: application/json" \
				-H "Authorization: Bearer $OPENAI_API_KEY" \
				-d "$payload" -k -L -s \
				--connect-timeout 10 --max-time 60 --retry 2 --retry-delay 0 --retry-max-time 120)
			
			[[ "$response" != "" ]] && break
			should_retry
		done

		echo -e "$(date) response: \n $response \n" >> log.txt

		answer=$(jq -r '.choices[].message.content' <<< "$response")	
		printf "\n $answer \n\n"

		answer=$(echo $answer | sed 's/"/\\"/g') # escape double quotes
		
		assistant_message='{"role": "assistant", "content": "'$answer'"}'

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $assistant_message")

		prompt=""
	done
}

### MAIN ###

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then 
	cat usage.txt

elif [[ ( $1 == "--chat") ||  $1 == "-c" ]]; then 	
	start_chat "${@:2}"

elif [[ ( $1 == "--code") ||  $1 == "-C" ]]; then 
	lang="$2"
	while [ "$lang" == "" ]; do
		read -e -p "language: " lang
	done

	while [ "$prompt" == "" ]; do
		read -e -p "code generation prompt: " prompt
	done

	prompt_once "$OPENAI_CODE_PREFIX \n\n [lang]: $lang \n\n [prompt]: $prompt"

elif [[ ( $1 == "--shell") ||  $1 == "-s" ]]; then 
	source /etc/*-release
	my_os="$(uname) $(echo $DISTRIB_ID) $(echo $DISTRIB_RELEASE)"	

	prompt="${@:2}"
	while [ "$prompt" == "" ]; do
		read -e -p "shell generation prompt: " prompt
	done

	prompt_once "$OPENAI_SHELL_PREFIX \n\n [os]: $my_os \n\n [prompt]: $prompt"

else	
	prompt="$@"
	while [ "$prompt" == "" ]; do
		read -e -p "prompt once: " prompt
	done

	prompt_once $prompt
fi