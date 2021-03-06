from download import download_cycles_info
from plot import plot_map
from tweeter import tweet

VERSION = "1.1"


def execute():
    information = download_cycles_info()
    map_image = plot_map(information, VERSION)
    tweet(map_image)


def handler(event, context):
    execute()
    return {"success": True}
