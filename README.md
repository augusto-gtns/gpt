# GPT3 script

Shell script to interact with GPT3 on your terminal.

## Installation
--- 

Clone this repo or download the `gpt3.sh` script.

```bash
git clone https://github.com/augusto-gtns/gpt3.git
```

Generate and set your personal API key (https://platform.openai.com/account/api-keys)

```bash
export OPENAI_API_KEY=mykey
```

Set execution permission.

```bash
chmod +x gpt3.sh
```

Run the script on your terminal

- call the script
    
    ```bash
    ./gpt3.sh
    ```

- Or map an alias on your shel configuration (`.bashrc`, `.zshrc` or others) and call the given alias

    ```bash
    alias gpt3="~/gpt3.sh"
    ```
     
    ```bash
    gpt3
    ```

## Usage
--- 

### Prompt once 

**[prompt]**

```bash
gpt3 what is the top 3 most popular programing languages
```

### Start a new chat session 

**[--chat|-c] [assitant-role]**

> The a assitant role is used to tell the chat the which role should be act.

- Using the default assitant role
  
    ```bash
    gpt3 --chat
    ```

- Suplly a custom assitant role
  
    ```bash
    gpt3 -c You are a tech expert
    ```

### Generate shell commands

**[--shell|-s] [prompt]**

```bash
gpt3 --shell
```

```bash
gpt3 -s list the name path and size of the 5 biggest files on my machine
```

### Generate code

**[--code|-C] [lang]**

```bash
gpt3 --code
```

```bash
gpt3 -C java
```

### See the usage heper:

**[--help|-h]**

```bash
gpt3 -h
```

```bash
gpt3 --help
```

## Configuration

Available envinroment variables. Run `gpt3 --help` to check the default values.

| Var                 | Description                                                                                                                                                            |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OPENAI_API_KEY      | Your personal API key.                                                                                                                                                 |
| OPENAI_TEMPERATURE  | Default temperature for API calls.<br /> higher values make the output more random, lower values like make it more focused and deterministic [values between 0 and 2]. |
| OPENAI_CHAT_ROLE    | Default assistant role to start a new chat sessions.                                                                                                                   |
| OPENAI_SHELL_PREFIX | Default prefix to --shell prompts.                                                                                                                                     |
| OPENAI_CODE_PREFIX  | Default prefix to --code prompts.                                                                                                                                      |
> The a assitant role is used to tell the chat the which role should be act.
## Reference
---

- [OpenAI API docs](https://platform.openai.com/docs/api-reference)
