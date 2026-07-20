import importlib.util
from pathlib import Path

import pytest


MODULE_PATH = Path(__file__).parents[1] / "meet_bot.py"
SPEC = importlib.util.spec_from_file_location("meet_bot_under_test", MODULE_PATH)
meet_bot = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(meet_bot)


class State:
    def __init__(self):
        self.auth_mode = "unknown"

    def set(self, **updates):
        for key, value in updates.items():
            setattr(self, key, value)


class EmptyLocator:
    @property
    def first(self):
        return self

    def count(self):
        return 0

    def is_visible(self):
        return False

    def is_enabled(self):
        return False

    def evaluate_all(self, _script):
        return []


class JoinPage:
    def __init__(self, click_results):
        self.click_results = iter(click_results)

    def get_by_role(self, *_args, **_kwargs):
        return EmptyLocator()

    def locator(self, _selector):
        return EmptyLocator()

    def evaluate(self, _script, *_args):
        return next(self.click_results)


class AuthProbePage:
    def __init__(self, result=None, error=None):
        self.result = result
        self.error = error

    def evaluate(self, _script):
        if self.error:
            raise self.error
        return self.result


class Browser:
    def __init__(self):
        self.context_args = None
        self.context = object()

    def new_context(self, **kwargs):
        self.context_args = kwargs
        return self.context


class Chromium:
    def __init__(self):
        self.launch_args = None
        self.persistent_args = None
        self.browser = Browser()
        self.persistent_context = object()

    def launch(self, **kwargs):
        self.launch_args = kwargs
        return self.browser

    def launch_persistent_context(self, **kwargs):
        self.persistent_args = kwargs
        return self.persistent_context


@pytest.mark.parametrize(
    ("probe_result", "expected"),
    [("guest", "guest"), ("authenticated", "authenticated"), (None, "unknown")],
)
def test_detect_auth_mode_requires_positive_dom_evidence(probe_result, expected):
    assert meet_bot._detect_auth_mode(AuthProbePage(result=probe_result)) == expected


def test_detect_auth_mode_returns_unknown_when_dom_probe_fails():
    assert meet_bot._detect_auth_mode(AuthProbePage(error=RuntimeError("rendering"))) == "unknown"


def test_click_join_retries_guest_name_until_field_is_ready(monkeypatch):
    state = State()
    page = JoinPage(["Ask to join"])
    fill_attempts = []

    monkeypatch.setattr(meet_bot, "_detect_auth_mode", lambda _page: "guest")

    def delayed_fill(_page, _guest_name):
        fill_attempts.append(1)
        if len(fill_attempts) == 1:
            return False, "guest name field not ready"
        return True, ""

    monkeypatch.setattr(meet_bot, "_try_guest_name", delayed_fill)
    monkeypatch.setattr(meet_bot.time, "sleep", lambda _seconds: None)

    clicked, error, lobby_waiting = meet_bot._click_join(page, state, "C2")

    assert clicked is True
    assert error == ""
    assert lobby_waiting is True
    assert len(fill_attempts) == 2
    assert state.auth_mode == "guest"


def test_click_join_does_not_mark_unknown_session_authenticated(monkeypatch):
    state = State()
    page = JoinPage(["Join now"])

    monkeypatch.setattr(meet_bot, "_detect_auth_mode", lambda _page: "unknown")
    monkeypatch.setattr(
        meet_bot,
        "_try_guest_name",
        lambda *_args: pytest.fail("guest fill should not run without guest evidence"),
    )

    clicked, error, lobby_waiting = meet_bot._click_join(page, state, "C2")

    assert clicked is True
    assert error == ""
    assert lobby_waiting is False
    assert state.auth_mode == "unknown"


def test_launch_context_uses_native_storage_state_when_auth_file_exists(tmp_path):
    auth_path = tmp_path / "auth.json"
    auth_path.write_text('{"cookies": [], "origins": []}')
    chromium = Chromium()
    context_args = {"viewport": {"width": 1280, "height": 800}}

    context, browser = meet_bot._launch_meet_context(
        chromium=chromium,
        headed=True,
        profile_dir=tmp_path / "profile",
        auth_state=str(auth_path),
        chrome_args=["--no-sandbox"],
        context_args=context_args,
    )

    assert context is chromium.browser.context
    assert browser is chromium.browser
    assert chromium.launch_args == {"headless": False, "args": ["--no-sandbox"]}
    assert chromium.browser.context_args == {
        **context_args,
        "storage_state": str(auth_path),
    }
    assert chromium.persistent_args is None


def test_launch_context_uses_persistent_profile_without_auth_state(tmp_path):
    chromium = Chromium()
    context_args = {"viewport": {"width": 1280, "height": 800}}

    context, browser = meet_bot._launch_meet_context(
        chromium=chromium,
        headed=False,
        profile_dir=tmp_path / "profile",
        auth_state="",
        chrome_args=[],
        context_args=context_args,
    )

    assert context is chromium.persistent_context
    assert browser is None
    assert chromium.persistent_args == {
        "user_data_dir": str(tmp_path / "profile"),
        "headless": True,
        "args": [],
        **context_args,
    }
    assert chromium.launch_args is None
