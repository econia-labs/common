# cspell:word dotenv

import os
import json
import boto3
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
from dotenv import load_dotenv

class SlackBot:
    def __init__(self):

        # Try local .env file first.
        load_dotenv()
        token = os.getenv('SLACK_BOT_TOKEN')

        # If no local token, try AWS Secrets Manager.
        if not token:
            try:
                session = boto3.session.Session()
                client = session.client('secretsmanager')
                response = client.get_secret_value(
                    SecretId='LINEAR_SLACK_BOT_TOKEN'
                )
                token = json.loads(response['SecretString'])['SLACK_BOT_TOKEN']
            except Exception as e:
                print(f"Error getting AWS secret: {e}")

        if not token:
            raise ValueError("No Slack token found in .env or AWS Secrets Manager")

        self.client = WebClient(token=token)

    def send_message(self, channel="#bot-test", text="hello"):
        """Send a message to Slack."""
        try:
            response = self.client.chat_postMessage(
                channel=channel,
                text=text
            )
            print(f"Message sent: {response['ts']}")
            return response
        except SlackApiError as e:
            print(f"Error: {e.response['error']}")
            raise e

if __name__ == "__main__":
    """Local development entry point."""
    bot = SlackBot()
    bot.send_message()
