#!/bin/bash

###
# init env
###

if [ "$OPENAI_API_KEY" == "" ]; then
	printf "\n - please set OPENAI_API_KEY env var (export OPENAI_API_KEY=mykey) \n"
	exit
fi

# Initial message for chat
[[ -z "${OPENAI_DEFAULT_ROLE}" ]] && OPENAI_DEFAULT_ROLE="You are a helpful assistant"

# What sampling temperature to use, between 0 and 2. 
# Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.
[[ -z "${OPENAI_DEFAULT_TEMPERATURE}" ]] && OPENAI_DEFAULT_TEMPERATURE=0.5

###
# functions
###

display_usage(){
	echo "
1) Prompt once using completion API (https://platform.openai.com/docs/api-reference/completions) 
	
	<prompt>

	gpt3 how to install wget on linux
	gpt3 \"what is the top 3 most popular programing languages?\"

2) Starts a new session using chat API (https://platform.openai.com/docs/api-reference/chat)

	[--chat|-c] <assitant role>

	gpt3 -c
	gpt3 -c You are a tech expert 

3) See this usage heper
	
	[--help|-h|]

	gpt3 -h

4) Envinroment configurations:

	- OPENAI_API_KEY: ******

	  Your personal API key.


	- OPENAI_DEFAULT_TEMPERATURE: $OPENAI_DEFAULT_TEMPERATURE

	  Default temperature for API calls.


	- OPENAI_DEFAULT_ROLE: $OPENAI_DEFAULT_ROLE

	  Default initial assistant message to start a new chat session.
	  A custom message can be used by supplying --chat option.
	  Used to tell the chat the which role should be act.
"
}

quick_prompt(){
	
	payload='{
		"model": "text-davinci-003",
		"temperature": '$OPENAI_DEFAULT_TEMPERATURE',
		"max_tokens": 500,
		"prompt": "'$prompt'"
	}'
	# echo "payload: $payload"
	
	response=$(curl https://api.openai.com/v1/completions \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $OPENAI_API_KEY" \
		-d "$payload" \
		-k -L -s --connect-timeout 5 \
	)
	# echo "response: $response"
	
	answer=$(jq -r '.choices[].text' <<< "${response}")	
	printf "$answer \n"
}

start_chat(){

	if [ "$role" == "" ]; then
		role=$OPENAI_DEFAULT_ROLE
	fi
	printf "\n- assistant role: $role\n\n"

	payload='{
		"model": "gpt-3.5-turbo",
		"temperature": '$OPENAI_DEFAULT_TEMPERATURE',
		"messages": [
			{"role": "assistant", "content": "'$role'"}
		]
	}'
	# echo $payload

	while [ true ]; do

		while [ "$prompt" == "" ]; do
			read -p "you: " prompt
		done
		# echo "prompt: $prompt"

		user_message='{"role": "user", "content": "'$prompt'"}'
		# echo "user_message: $user_message"		

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $user_message")
		# echo "payload: $payload"		

		response=$(curl https://api.openai.com/v1/chat/completions \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $OPENAI_API_KEY" \
			-d "$payload" \
			-k -L -s --connect-timeout 10 \
		)
		# echo "$response"
		
		answer=$(jq -r '.choices[].message.content' <<< "${response}")	
		printf "\n $answer \n\n"

		assistant_message='{"role": "assistant", "content": "'$answer'"}'
		# echo "assistant_message: $assistant_message"

		payload=$(echo $payload | jq ".messages[.messages| length] |= . + $assistant_message")
		# echo "payload: $payload"		

		prompt=""
	done
}

###
# MAIN
###

if [[ ( $1 == "--help") ||  $1 == "-h" ||  $@ == "" ]]; then 
	# echo "display_usage"	
	display_usage

elif [[ ( $1 == "--chat") ||  $1 == "-c" ]]; then 
	# echo "start_chat"
	
	role="${@:2}"
	# echo "role: $role"
	
	start_chat
else
	# echo "quick_prompt"

	prompt="$@"
	# echo "prompt: $prompt"
	
	quick_prompt
fi
