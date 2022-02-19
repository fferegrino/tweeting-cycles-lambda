import os
from datetime import datetime

from twython import Twython


def tweet(image_path: str) -> None:

    app_key = os.environ["API_KEY"]
    app_secret = os.environ["API_SECRET"]
    oauth_token = os.environ["ACCESS_TOKEN"]
    oauth_token_secret = os.environ["ACCESS_TOKEN_SECRET"]
    twitter = Twython(app_key, app_secret, oauth_token, oauth_token_secret)

    now = datetime.now().strftime("%m/%d/%Y, %H:%M")

    with open(image_path, "rb") as cycles_png:
        image = twitter.upload_media(media=cycles_png)

    twitter.update_status(status=f"London Cycles update at {now}", media_ids=[image["media_id"]])
