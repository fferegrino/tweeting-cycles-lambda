from unittest.mock import patch
import pandas as pd
import pytest

from app import execute


@pytest.fixture
def patch_download_cycles_info(pytestconfig):
    sample_df = pd.read_csv(pytestconfig.rootdir / "tests" / "sample.csv")
    with patch("app.download_cycles_info", return_value=sample_df) as patched:
        yield patched


def test_exclude(patch_download_cycles_info):
    with patch("app.tweet") as tweet_patched:
        execute()
        patch_download_cycles_info.assert_called_once()
        tweet_patched.assert_called_once()
