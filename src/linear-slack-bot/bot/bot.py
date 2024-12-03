import os
import json
import boto3
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
from dotenv import load_dotenv

class SlackBot:

    def __init__(self):
        self.token = self._get_token()
        self.client = WebClient(token=self.token)

    def _get_token(self):
        """Get token from environment or AWS Secrets Manager."""

        # First try local .env file.
        load_dotenv()
        token = os.getenv('SLACK_BOT_TOKEN')
        if token:
            print("Using token from .env file")
            return token

        # If no .env token, try AWS.
        try:
            secret_arn = os.getenv('SLACK_SECRET_ARN')
            if secret_arn:
                print("Getting token from AWS Secrets Manager")
                session = boto3.session.Session()
                client = session.client('secretsmanager')
                response = client.get_secret_value(SecretId=secret_arn)
                secrets = json.loads(response['SecretString'])
                return secrets['SLACK_BOT_TOKEN']
        except Exception as e:
            print(f"Error getting AWS secret: {e}")

        raise ValueError("No Slack token found in .env or AWS Secrets Manager")

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
