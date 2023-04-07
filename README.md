# GPT script

Shell script to interact with GPT on your terminal.

## Installation

Clone this repo or download the `gpt.sh` script.

```bash
git clone https://github.com/augusto-gtns/gpt.git
```

Generate and set your personal API key (https://platform.openai.com/account/api-keys)

```bash
export OPENAI_API_KEY=mykey
```

Set execution permission.

```bash
chmod +x gpt.sh
```

Run the script on your terminal

- call the script

  ```bash
  ./gpt.sh
  ```

- or map an alias on your shell configuration (`.bashrc`, `.zshrc` or others) and call the given alias

  ```bash
  alias gpt="~/gpt.sh"
  ```

  ```bash
  gpt
  ```

## Usage

### Prompt once

**[prompt]**

```bash
gpt what is the top 3 most popular programing languages
```

### Start a new chat session

**[--chat|-c] [assistant-role]**

> The assistant role is used to tell the chat which role should be acted.

- Using the default assistant role

  ```bash
  gpt --chat
  ```

- Supply a custom assistant role

  ```bash
  gpt -c You are a tech expert
  ```

### Generate shell commands

**[--shell|-s] [prompt]**

```bash
gpt --shell
```

```bash
gpt -s list the name path and size of the 5 biggest files on my machine
```

### Generate code

**[--code|-C] [lang]**

```bash
gpt --code
```

```bash
gpt -C java
```

### See the usage helper:

**[--help|-h]**

```bash
gpt -h
```

```bash
gpt --help
```

## Configuration

Available environment variables. Run `gpt --help` to check the default values.

| Var                 | Description                                                                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OPENAI_API_KEY      | Your personal API key.                                                                                                                                     |
| OPENAI_TEMPERATURE  | Default temperature for API calls. Values between 0 and 2. Higher values make the output more random, lower values make it more focused and deterministic. |
| OPENAI_CHAT_ROLE    | Default assistant role to start a new chat sessions.                                                                                                       |
| OPENAI_SHELL_PREFIX | Default prefix to --shell prompts.                                                                                                                         |
| OPENAI_CODE_PREFIX  | Default prefix to --code prompts.                                                                                                                          |

## Reference

- [OpenAI API docs](https://platform.openai.com/docs/api-reference)
