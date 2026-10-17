import pytest

from app.services.inference import _clasificar


@pytest.mark.parametrize(
    "crudo, esperado",
    [
        ("dirt", "partícula orgánica"),
        ("fiber", "fibra"),
        ("fragment", "fragmento"),
        ("pellet", "gránulo"),
        ("Fiber", "fibra"),
        ("fragmento", "fragmento"),
    ],
)
def test_mapeo_clases_microplasticos(crudo, esperado):
    assert _clasificar(crudo) == esperado


def test_clase_desconocida_se_conserva():
    assert _clasificar("car") == "car"
    assert _clasificar("") == "desconocida"
