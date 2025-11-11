def test_imports():
    import src.io.loader as _io
    import src.sed.models as _sed
    import src.fit.bic as _fit
    import src.score.iwi as _iwi
    import src.vetting.tree as _vet
    # Acceso a símbolos clave
    assert hasattr(_io, 'load_table')
    assert hasattr(_sed, 'blackbody_nu')
    assert hasattr(_fit, 'bic')
    assert hasattr(_iwi, 'iwi')
    assert hasattr(_vet, 'is_clean_allwise_row')
