"""pytest fixtures shared across the contract tests."""

import os
import pytest

from client import Client, allow_writes


@pytest.fixture(scope="session")
def client():
    if not os.environ.get("CSP_API_KEY"):
        pytest.skip("CSP_API_KEY is required to run contract tests")
    return Client()


@pytest.fixture(scope="session")
def writes_allowed():
    return allow_writes()


def pytest_collection_modifyitems(config, items):
    if allow_writes():
        return
    skip_writes = pytest.mark.skip(reason="set CSP_ALLOW_WRITES=1 to run write-side tests")
    for item in items:
        if "writes" in item.keywords:
            item.add_marker(skip_writes)
