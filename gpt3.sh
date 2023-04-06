#!/bin/bash

###
# init env
###

if [ "$OPENAI_API_KEY" == "" ]; then
	printf "\n please set OPENAI_API_KEY env var \n"
	exit
fi

[[ -z "${OPENAI_TEMPERATURE}" ]] && OPENAI_TEMPERATURE=0.5

[[ -z "${OPENAI_MAX_TOKENS}" ]] && OPENAI_MAX_TOKENS=500

[[ -z "${OPENAI_CHAT_ROLE}" ]] && OPENAI_CHAT_ROLE="You are a helpful assistant."

[[ -z "${OPENAI_SHELL_PREFIX}" ]] && OPENAI_SHELL_PREFIX="Generate a shell command compatible with the operating system [os] and that responds to [prompt]. Add a brief explanation of the generated command."

[[ -z "${OPENAI_CODE_PREFIX}" ]] && OPENAI_CODE_PREFIX="Generate code for the language [lang] and that responds to the [prompt]. Add a brief explanation of the generated code."

###
# functions
###

display_usage(){
	echo "

See https://github.com/augusto-gtns/gpt3.

Environment configuration values:

	OPENAI_API_KEY: ******
	
	OPENAI_TEMPERATURE: $OPENAI_TEMPERATURE

	OPENAI_MAX_TOKENS: $OPENAI_MAX_TOKENS

	OPENAI_CHAT_ROLE: $OPENAI_CHAT_ROLE

	OPENAI_SHELL_PREFIX: $OPENAI_SHELL_PREFIX
	
	OPENAI_CODE_PREFIX: $OPENAI_CODE_PREFIX
	"
}

quick_prompt(){
	prompt="$@"

	payload='{
		"model": "text-davinci-003",
		"temperature": '$OPENAI_TEMPERATURE',
		"max_tokens": '$OPENAI_MAX_TOKENS',
		"prompt": "'$prompt'"
	}'
	
	response=$(curl https://api.openai.com/v1/completions \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $OPENAI_API_KEY" \
		-d "$payload" \
		-k -L -s --connect-timeout 5)

	answer=$(jq -r '.choices[].text' <<< "${response}")	
	printf "$answer \n"
}

start_chat(){
	role="$@"

	if [ "$role" == "" ]; then
		role=$OPENAI_CHAT_ROLE
	fi
	printf "\n🔹assistant role: $role\n\n"

	payload='{
		"model": "gpt-3.5-turbo",
		"temperature": '$OPENAI_TEMPERATURE',
		"messages": [
			{"role": "assistant", "content": "'$role'"}
		]
	}'

	while [ true ]; do

		while [ "$prompt" == "" ]; do
			read -e -p "🔹you: " prompt
		done

		user_message='{"role": "user", "content": "'$prompt'"}'

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $user_message")

		response=$(curl https://api.openai.com/v1/chat/completions \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $OPENAI_API_KEY" \
			-d "$payload" \
			-k -L -s --connect-timeout 10)
		
		answer=$(jq -r '.choices[].message.content' <<< "${response}")	
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

	quick_prompt "$OPENAI_CODE_PREFIX \n\n [lang]: $lang \n\n [prompt]: $prompt"

elif [[ ( $1 == "--shell") ||  $1 == "-s" ]]; then 
	
	source /etc/lsb-release
	my_os="$(uname) $(echo $DISTRIB_ID) $(echo $DISTRIB_RELEASE)"	

	prompt="${@:2}"
	while [ "$prompt" == "" ]; do
		read -e -p "shell generation prompt: " prompt
	done

	quick_prompt "$OPENAI_SHELL_PREFIX \n\n [os]: $my_os \n\n [prompt]: $prompt"

else	
	prompt="$@"
	while [ "$prompt" == "" ]; do
		read -e -p "prompt once: " prompt
	done

	quick_prompt $prompt
fi
