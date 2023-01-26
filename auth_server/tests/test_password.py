from auth import model


def test_check_password():
    new_user = model.User.make_new(email=b"test@test.example", password=b"toto")
    assert new_user.check_password(b"toto")
    assert not new_user.check_password(b"foo")
    assert not new_user.check_password(b"deezdzed")
    assert not new_user.check_password(b"fieiehe")
    assert not new_user.check_password(b"boo")
    assert not new_user.check_password(b"fol")
    assert not new_user.check_password(b"ffo")
    assert new_user.check_password(b"toto")
