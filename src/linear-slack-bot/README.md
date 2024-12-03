# Slack Linear Bot

A bot that posts Linear task completion metrics to Slack.

## Local development

1. Create virtual environment:

   ```sh
   python -m venv bot-venv
   ```

1. Activate virtual environment:

   ```sh
   # On Mac/Linux:
   source bot-venv/bin/activate

   # On Windows:
   bot-venv\Scripts\activate
   ```

1. Install dependencies:

   ```sh
   pip install -r requirements.txt
   ```

1. Create `.env` file:

   ```env
   SLACK_BOT_TOKEN=xoxb-your-token
   ```

## Running Locally

Make sure virtual environment is activated, then:

```sh
python bot/bot.py
```

## Updating Dependencies

With virtual environment activated:

```sh
pip freeze > requirements.txt
```
