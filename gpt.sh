#!/bin/bash

###
# init env
###

# navigate to absolute path
cd $(dirname "$0") || exit

source .env # default env config

[[ -f .env.custom ]] && source .env.custom # custom config

if [ "$OPENAI_API_KEY" == "" ]; then
	printf "\n please set OPENAI_API_KEY env var \n"
	exit
fi

###
# functions
###

display_usage(){
	echo "
	[prompt]: 			prompt once

	[--chat|-c] [assistant-role]: 	start a chat session

	[--shell|-s] [prompt]:		generate shell comands

	[--code|-C] [language]: 	generate code to a given language

	[--help|-h]:			display usage helper

	See more on README.md or https://github.com/augusto-gtns/gpt
	"
}

should_retry(){
	try_again=""
	while [[ "$try_again" != "y" && "$try_again" != "n" ]]; do
		read -e -p "🔸no answer receiveid, try again? (y/n): " try_again
	done
	if [ "$try_again" == "n" ]; then
		exit 0
	fi
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
			-d "$payload" \
			-k -L -s \
			--connect-timeout 10 --max-time 60 --retry 2 --retry-delay 0 --retry-max-time 120)
		
		if [ "$response" != "" ]; then
			break
		else
			should_retry
		fi
	done

	echo -e "$(date) response: \n $response \n" >> log.txt

	answer=$(jq -r '.choices[].text' <<< "$response")	
	printf "$answer \n"
}

start_chat(){
	role="$@"

	if [ "$role" == "" ]; then
		role=$OPENAI_CHAT_ROLE
	fi
	printf "\n🔹assistant role: $role\n\n"

	payload='{
		"model": "'$OPENAI_CHAT_MODEL'",
		"temperature": '$OPENAI_CHAT_TEMPERATURE',
		"messages": [
			{"role": "assistant", "content": "'$role'"}
		]
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
				-d "$payload" \
				-k -L -s \
				--connect-timeout 10 --max-time 60 --retry 2 --retry-delay 0 --retry-max-time 120)
			
			if [ "$response" != "" ]; then
				break
			else 
				should_retry
			fi
		done

		echo -e "$(date) response: \n $response \n" >> log.txt

		answer=$(jq -r '.choices[].message.content' <<< "$response")	
		printf "\n $answer \n\n"

		# escape double quotes
		answer=$(echo $answer | sed 's/"/\\"/g')
		
		assistant_message='{"role": "assistant", "content": "'$answer'"}'

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $assistant_message")

		prompt=""
	done
}

###
# MAIN
###

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then 
	display_usage

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
	
	source /etc/lsb-release
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
