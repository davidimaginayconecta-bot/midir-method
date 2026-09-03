Attribute VB_Name = "IKEA_Facturas"
Option Explicit

Private Const MAX_LINEAS As Long = 39 'Filas 25 a 63
Private Const IVA_PORC As Double = 0.21
Private Const FOLDER_PICKER As Long = 4

Public Sub Instalar_Boton_IKEA()
    Dim ws As Worksheet
    Dim shp As Shape
    Dim btnLeft As Double
    Dim btnTop As Double
    Dim btnWidth As Double
    Dim btnHeight As Double

    On Error GoTo ErrHandler

    Set ws = ThisWorkbook.Worksheets("CONTROL")

    On Error Resume Next
    ws.Shapes("btnGenerarFacturasIKEA").Delete
    On Error GoTo ErrHandler

    btnLeft = ws.Range("B9").Left
    btnTop = ws.Range("B9").Top
    btnWidth = 240
    btnHeight = 44

    Set shp = ws.Shapes.AddShape(msoShapeRoundedRectangle, btnLeft, btnTop, btnWidth, btnHeight)
    With shp
        .Name = "btnGenerarFacturasIKEA"
        .TextFrame2.TextRange.Text = "GENERAR FACTURAS IKEA"
        .OnAction = "Ejecutar_IKEA"
        .Fill.ForeColor.RGB = RGB(0, 102, 204)
        .TextFrame2.TextRange.Font.Fill.ForeColor.RGB = RGB(255, 255, 255)
        .TextFrame2.TextRange.Font.Bold = msoTrue
    End With

    MsgBox "Botón instalado en hoja CONTROL.", vbInformation
    Exit Sub

ErrHandler:
    MsgBox "Error instalando botón: " & Err.Description, vbExclamation
End Sub

Public Sub Ejecutar_IKEA()
    Dim carpetaFacturas As String
    Dim carpetaAlbaranes As String
    Dim carpetaSalida As String
    Dim exportarPDF As Boolean

    carpetaFacturas = SeleccionarCarpeta("Selecciona carpeta FACTURAS (PDF)")
    If Len(carpetaFacturas) = 0 Then
        MsgBox "Operación cancelada. Debes seleccionar FACTURAS.", vbExclamation
        Exit Sub
    End If

    carpetaAlbaranes = SeleccionarCarpeta("Selecciona carpeta ALBARANES (PDF)")
    If Len(carpetaAlbaranes) = 0 Then
        MsgBox "Operación cancelada. Debes seleccionar ALBARANES.", vbExclamation
        Exit Sub
    End If

    carpetaSalida = SeleccionarCarpeta("Selecciona carpeta SALIDA")
    If Len(carpetaSalida) = 0 Then
        MsgBox "Operación cancelada. Debes seleccionar SALIDA.", vbExclamation
        Exit Sub
    End If

    With ThisWorkbook.Worksheets("CONTROL")
        .Range("B1").Value = carpetaFacturas
        .Range("B2").Value = carpetaAlbaranes
        .Range("B3").Value = carpetaSalida
        exportarPDF = ValorBooleano(.Range("B6").Value)
    End With

    ProcesarLoteFacturasIKEA carpetaFacturas, carpetaAlbaranes, carpetaSalida, exportarPDF
End Sub

Private Sub ProcesarLoteFacturasIKEA(ByVal carpetaFacturas As String, ByVal carpetaAlbaranes As String, ByVal carpetaSalida As String, ByVal exportarPDF As Boolean)
    Dim nombrePdf As String
    Dim rutaFactura As String
    Dim wordApp As Object
    Dim logPath As String
    Dim contadorOK As Long
    Dim contadorError As Long

    On Error GoTo FatalError

    logPath = AgregarBarra(carpetaSalida) & "IKEA_log.txt"
    AnexarLog logPath, "===== Inicio lote IKEA: " & Format(Now, "yyyy-mm-dd hh:nn:ss") & " ====="

    Set wordApp = CreateObject("Word.Application")
    wordApp.Visible = False

    nombrePdf = Dir(AgregarBarra(carpetaFacturas) & "*.pdf")
    If Len(nombrePdf) = 0 Then
        MsgBox "No se encontraron PDFs en la carpeta FACTURAS.", vbExclamation
        GoTo Finalizar
    End If

    Do While Len(nombrePdf) > 0
        rutaFactura = AgregarBarra(carpetaFacturas) & nombrePdf
        On Error GoTo ErrorFactura

        ProcesarUnaFactura rutaFactura, carpetaAlbaranes, carpetaSalida, exportarPDF, wordApp, logPath
        contadorOK = contadorOK + 1
        GoTo Siguiente

ErrorFactura:
        contadorError = contadorError + 1
        AnexarLog logPath, "ERROR | " & nombrePdf & " | " & Err.Number & " | " & Err.Description
        MsgBox "Error procesando " & nombrePdf & vbCrLf & "(" & Err.Number & ") " & Err.Description, vbExclamation
        Err.Clear

Siguiente:
        On Error GoTo FatalError
        nombrePdf = Dir()
    Loop

Finalizar:
    If Not wordApp Is Nothing Then
        On Error Resume Next
        wordApp.Quit False
        On Error GoTo 0
    End If

    AnexarLog logPath, "===== Fin lote IKEA: OK=" & contadorOK & " ERROR=" & contadorError & " ====="
    MsgBox "Proceso finalizado. OK=" & contadorOK & " | ERROR=" & contadorError, vbInformation
    Exit Sub

FatalError:
    If Not wordApp Is Nothing Then
        On Error Resume Next
        wordApp.Quit False
        On Error GoTo 0
    End If
    AnexarLog logPath, "ERROR FATAL | " & Err.Number & " | " & Err.Description
    MsgBox "Error fatal: " & Err.Description, vbCritical
End Sub

Private Sub ProcesarUnaFactura(ByVal rutaFacturaPdf As String, ByVal carpetaAlbaranes As String, ByVal carpetaSalida As String, ByVal exportarPDF As Boolean, ByVal wordApp As Object, ByVal logPath As String)
    Dim txtFactura As String
    Dim dataFactura As Object
    Dim albaranes As Collection
    Dim infoEntrega As Object
    Dim wbOut As Workbook
    Dim wsOut As Worksheet
    Dim numFactura As String
    Dim rutaXlsx As String
    Dim rutaPdfOut As String
    Dim nombreBase As String

    txtFactura = ExtraerTextoPDF_Word(rutaFacturaPdf, wordApp)
    If Len(Trim$(txtFactura)) < 40 Then
        Err.Raise vbObjectError + 1101, , "PDF sin texto o Word no pudo abrirlo"
    End If

    Set dataFactura = ParsearFactura(txtFactura)

    If Len(dataFactura("numFactura")) = 0 Then
        Err.Raise vbObjectError + 1102, , "No se encontró Nº de factura"
    End If
    If dataFactura("totalFactura") = 0 Then
        Err.Raise vbObjectError + 1103, , "No se encontró total_factura"
    End If
    If dataFactura("lineas").Count = 0 Then
        Err.Raise vbObjectError + 1104, , "No se encontraron líneas de factura"
    End If

    Set albaranes = dataFactura("albaranes")
    Set infoEntrega = ObtenerInfoEntregaDesdeAlbaranes(albaranes, carpetaAlbaranes, wordApp)

    If Len(dataFactura("fechaEntrega")) = 0 Then
        dataFactura("fechaEntrega") = infoEntrega("fechaEntrega")
    End If
    If Len(dataFactura("personaContacto")) = 0 Then
        dataFactura("personaContacto") = infoEntrega("personaContacto")
    End If
    If Len(dataFactura("unidadTienda")) = 0 Then
        dataFactura("unidadTienda") = infoEntrega("unidadTienda")
    End If

    AjustarIVAUltimaLinea dataFactura("lineas"), dataFactura("ivaTotal")

    If dataFactura("lineas").Count > MAX_LINEAS Then
        AnexarLog logPath, "WARN  | " & Mid$(rutaFacturaPdf, InStrRev(rutaFacturaPdf, "\") + 1) & " | Exceso de líneas: " & dataFactura("lineas").Count & " (máx " & MAX_LINEAS & ")"
    End If

    ThisWorkbook.Worksheets("PLANTILLA PARA USAR").Copy
    Set wbOut = ActiveWorkbook
    Set wsOut = wbOut.Worksheets(1)

    RellenarPlantilla wsOut, dataFactura, infoEntrega

    numFactura = LimpiarNombreArchivo(dataFactura("numFactura"))
    If Len(numFactura) = 0 Then numFactura = "SIN_NUMERO"

    nombreBase = "FACTURA_IKEA_" & numFactura
    rutaXlsx = AgregarBarra(carpetaSalida) & nombreBase & ".xlsx"
    wbOut.SaveAs Filename:=rutaXlsx, FileFormat:=51

    If exportarPDF Then
        On Error Resume Next
        rutaPdfOut = AgregarBarra(carpetaSalida) & nombreBase & ".pdf"
        wsOut.ExportAsFixedFormat Type:=xlTypePDF, Filename:=rutaPdfOut
        If Err.Number <> 0 Then
            AnexarLog logPath, "WARN  | " & Mid$(rutaFacturaPdf, InStrRev(rutaFacturaPdf, "\") + 1) & " | Export PDF: " & Err.Description
            Err.Clear
        End If
        On Error GoTo 0
    End If

    wbOut.Close SaveChanges:=False

    If Abs((dataFactura("baseTotal") + dataFactura("ivaTotal")) - dataFactura("totalFactura")) > 0.05 Then
        AnexarLog logPath, "WARN  | " & Mid$(rutaFacturaPdf, InStrRev(rutaFacturaPdf, "\") + 1) & " | Total no cuadra: base+iva=" & FormatoImporte(dataFactura("baseTotal") + dataFactura("ivaTotal")) & " vs total=" & FormatoImporte(dataFactura("totalFactura"))
    End If

    AnexarLog logPath, "OK    | " & Mid$(rutaFacturaPdf, InStrRev(rutaFacturaPdf, "\") + 1) & " | Factura " & dataFactura("numFactura")
End Sub

Private Function ParsearFactura(ByVal txt As String) As Object
    Dim d As Object
    Dim lineas As Collection

    Set d = CreateObject("Scripting.Dictionary")
    d("numFactura") = ExtraerNumeroFactura(txt)
    d("fechaFactura") = ExtraerFechaTrasEtiqueta(txt, "Fecha de factura")
    d("fechaVencimiento") = ExtraerFechaTrasEtiqueta(txt, "Fecha vencimiento")
    d("fechaEntrega") = ExtraerFechaTrasEtiqueta(txt, "Fecha de entrega")
    d("personaContacto") = ExtraerValorTrasEtiqueta(txt, Array("Persona de contacto", "Contacto", "Atención"))
    d("unidadTienda") = ExtraerValorTrasEtiqueta(txt, Array("Unidad", "Tienda", "Centro"))
    d("referenciaCliente") = ExtraerReferenciaCliente(txt)

    Set lineas = ExtraerLineasFactura(txt)
    d("lineas") = lineas

    d("baseTotal") = 0#
    d("ivaTotal") = 0#
    d("totalFactura") = 0#
    ParsearTotales txt, d

    d("albaranes") = ExtraerAlbaranesAsociados(txt)

    Set ParsearFactura = d
End Function

Private Function ExtraerLineasFactura(ByVal txt As String) As Collection
    Dim out As New Collection
    Dim arr() As String
    Dim i As Long
    Dim ln As String
    Dim actual As Object
    Dim nueva As Object

    arr = Split(NormalizarSaltos(txt), vbLf)

    For i = LBound(arr) To UBound(arr)
        ln = Trim$(arr(i))
        If Len(ln) = 0 Then GoTo ContinueLoop

        If EsNuevaLineaArticulo(ln) Then
            Set nueva = ParsearLineaArticulo(ln)
            If Not nueva Is Nothing Then
                If Not actual Is Nothing Then out.Add actual
                Set actual = nueva
            End If
        ElseIf Not actual Is Nothing Then
            If Not EsCabeceraOTotal(ln) Then
                If TieneImporteEspanol(ln) Then
                    If IntentarCompletarLineaDesdeSiguiente actual, ln Then
                        'completada
                    Else
                        actual("descripcion") = Trim$(actual("descripcion") & " " & ln)
                    End If
                Else
                    actual("descripcion") = Trim$(actual("descripcion") & " " & ln)
                End If
            End If
        End If
ContinueLoop:
    Next i

    If Not actual Is Nothing Then out.Add actual
    Set ExtraerLineasFactura = out
End Function

Private Function EsNuevaLineaArticulo(ByVal ln As String) As Boolean
    Dim rgx As Object
    Set rgx = CreateObject("VBScript.RegExp")
    rgx.Pattern = "^\s*\d+(?:[\.,]\d+)?\s+.*\d{1,3}(?:\.\d{3})*,\d{2}\s+\d{1,3}(?:\.\d{3})*,\d{2}\s*$"
    rgx.IgnoreCase = True
    EsNuevaLineaArticulo = rgx.Test(ln)
End Function

Private Function ParsearLineaArticulo(ByVal ln As String) As Object
    Dim rgx As Object
    Dim m As Object
    Dim nums As Collection
    Dim qtyRaw As String
    Dim c As Object

    Set nums = ExtraerImportesLinea(ln)
    If nums.Count < 2 Then Exit Function

    Set rgx = CreateObject("VBScript.RegExp")
    rgx.Pattern = "^\s*(\d+(?:[\.,]\d+)?)\s+(.*)$"
    If Not rgx.Test(ln) Then Exit Function

    Set m = rgx.Execute(ln)(0)
    qtyRaw = Replace(m.SubMatches(0), ".", "")
    qtyRaw = Replace(qtyRaw, ",", ".")

    Set c = CreateObject("Scripting.Dictionary")
    c("cantidad") = CDbl(Val(qtyRaw))
    c("precioUnitario") = CDbl(nums(nums.Count - 1))
    c("base") = CDbl(nums(nums.Count))
    c("descripcion") = LimpiarDescripcion(m.SubMatches(1), nums)
    c("ivaPorc") = 21
    c("ivaImporte") = Round(c("base") * IVA_PORC, 2)
    c("totalLinea") = c("base") + c("ivaImporte")

    Set ParsearLineaArticulo = c
End Function

Private Function IntentarCompletarLineaDesdeSiguiente(ByVal linea As Object, ByVal ln As String) As Boolean
    Dim nums As Collection
    Set nums = ExtraerImportesLinea(ln)
    If nums.Count >= 1 Then
        'solo si tiene claramente patrón de final de línea (base, etc.)
        If nums.Count >= 2 And InStr(1, ln, ",", vbTextCompare) > 0 Then
            linea("base") = CDbl(nums(nums.Count))
            linea("ivaImporte") = Round(linea("base") * IVA_PORC, 2)
            linea("totalLinea") = linea("base") + linea("ivaImporte")
            IntentarCompletarLineaDesdeSiguiente = True
            Exit Function
        End If
    End If
End Function

Private Function EsCabeceraOTotal(ByVal ln As String) As Boolean
    Dim u As String
    u = UCase$(ln)
    EsCabeceraOTotal = (InStr(u, "BASE IMPONIBLE") > 0) _
        Or (InStr(u, "TOTAL FACTURA") > 0) _
        Or (InStr(u, "IVA") > 0 And InStr(u, "%") > 0) _
        Or (InStr(u, "PÁGINA") > 0) _
        Or (InStr(u, "BASADO EN ENTREGAS") > 0)
End Function

Private Sub ParsearTotales(ByVal txt As String, ByRef d As Object)
    Dim arr() As String
    Dim i As Long
    Dim bloque As String
    Dim nums As Collection

    arr = Split(NormalizarSaltos(txt), vbLf)
    For i = LBound(arr) To UBound(arr)
        If InStr(1, arr(i), "BASE IMPONIBLE", vbTextCompare) > 0 Then
            bloque = arr(i)
            If i + 1 <= UBound(arr) Then bloque = bloque & " " & arr(i + 1)
            If i + 2 <= UBound(arr) Then bloque = bloque & " " & arr(i + 2)
            If i + 3 <= UBound(arr) Then bloque = bloque & " " & arr(i + 3)
            Exit For
        End If
    Next i

    If Len(bloque) = 0 Then
        bloque = Right$(txt, 1200)
    End If

    Set nums = ExtraerImportesLinea(bloque)
    If nums.Count >= 3 Then
        d("baseTotal") = CDbl(nums(nums.Count - 2))
        d("ivaTotal") = CDbl(nums(nums.Count - 1))
        d("totalFactura") = CDbl(nums(nums.Count))
    Else
        d("totalFactura") = ExtraerUltimoImporte(txt)
    End If
End Sub

Private Function ExtraerAlbaranesAsociados(ByVal txt As String) As Collection
    Dim out As New Collection
    Dim dict As Object
    Dim arr() As String
    Dim i As Long, j As Long
    Dim bloque As String
    Dim rgx As Object, mc As Object, m As Object
    Dim num As String

    Set dict = CreateObject("Scripting.Dictionary")
    arr = Split(NormalizarSaltos(txt), vbLf)

    For i = LBound(arr) To UBound(arr)
        If InStr(1, arr(i), "Basado en Entregas", vbTextCompare) > 0 Then
            bloque = arr(i)
            For j = i + 1 To WorksheetFunction.Min(i + 20, UBound(arr))
                If Len(Trim$(arr(j))) = 0 Then Exit For
                bloque = bloque & " " & arr(j)
            Next j
            Exit For
        End If
    Next i

    If Len(bloque) = 0 Then bloque = txt

    Set rgx = CreateObject("VBScript.RegExp")
    rgx.Global = True
    rgx.Pattern = "\b\d{2}\.??\d{3,}\b|\b\d{5,}\b"

    If rgx.Test(bloque) Then
        Set mc = rgx.Execute(bloque)
        For Each m In mc
            num = NormalizarNumeroAlbaran(CStr(m.Value))
            If Len(num) >= 4 Then
                If Not dict.Exists(num) Then dict.Add num, True
            End If
        Next m
    End If

    For Each num In dict.Keys
        out.Add CStr(num)
    Next num

    Set ExtraerAlbaranesAsociados = out
End Function

Private Function ObtenerInfoEntregaDesdeAlbaranes(ByVal albaranes As Collection, ByVal carpetaAlbaranes As String, ByVal wordApp As Object) As Object
    Dim info As Object
    Dim i As Long
    Dim num As String
    Dim rutaAlb As String
    Dim txt As String
    Dim infoAlb As Object
    Dim fechaMax As Date

    Set info = CreateObject("Scripting.Dictionary")
    info("direccion") = New Collection
    info("fechaEntrega") = ""
    info("personaContacto") = ""
    info("unidadTienda") = ""

    For i = 1 To albaranes.Count
        num = CStr(albaranes(i))
        rutaAlb = BuscarPdfAlbaran(carpetaAlbaranes, num)
        If Len(rutaAlb) = 0 Then GoTo ContinueLoop

        txt = ExtraerTextoPDF_Word(rutaAlb, wordApp)
        Set infoAlb = ParsearAlbaran(txt)

        If info("direccion").Count = 0 And infoAlb("direccion").Count > 0 Then
            CopiarCollection infoAlb("direccion"), info("direccion")
        End If

        If Len(info("personaContacto")) = 0 Then
            info("personaContacto") = infoAlb("personaContacto")
        End If

        If Len(info("unidadTienda")) = 0 Then
            info("unidadTienda") = infoAlb("unidadTienda")
        End If

        If Len(infoAlb("fecha")) > 0 Then
            If TryParseFecha(infoAlb("fecha"), fechaMax) Then
                If Len(info("fechaEntrega")) = 0 Then
                    info("fechaEntrega") = Format(fechaMax, "dd/mm/yyyy")
                Else
                    Dim fCur As Date
                    If TryParseFecha(info("fechaEntrega"), fCur) Then
                        If fechaMax > fCur Then info("fechaEntrega") = Format(fechaMax, "dd/mm/yyyy")
                    End If
                End If
            End If
        End If
ContinueLoop:
    Next i

    Set ObtenerInfoEntregaDesdeAlbaranes = info
End Function

Private Function ParsearAlbaran(ByVal txt As String) As Object
    Dim d As Object
    Dim arr() As String
    Dim i As Long
    Dim colDir As Collection
    Dim l As String

    Set d = CreateObject("Scripting.Dictionary")
    Set colDir = New Collection

    arr = Split(NormalizarSaltos(txt), vbLf)

    For i = LBound(arr) To UBound(arr)
        If InStr(1, arr(i), "Dirección de envío", vbTextCompare) > 0 Or InStr(1, arr(i), "Direccion de envio", vbTextCompare) > 0 Then
            Dim j As Long
            For j = i + 1 To WorksheetFunction.Min(i + 10, UBound(arr))
                l = Trim$(arr(j))
                If Len(l) = 0 Then Exit For
                If EsCabeceraOTotal(l) Then Exit For
                colDir.Add l
                If colDir.Count >= 5 Then Exit For
            Next j
            Exit For
        End If
    Next i

    d("direccion") = colDir
    d("fecha") = ExtraerPrimeraFecha(txt)
    d("personaContacto") = ExtraerValorTrasEtiqueta(txt, Array("Persona de contacto", "Contacto"))
    d("unidadTienda") = InferirUnidadDesdeDireccion(colDir)

    Set ParsearAlbaran = d
End Function

Private Sub RellenarPlantilla(ByVal ws As Worksheet, ByVal dataFactura As Object, ByVal infoEntrega As Object)
    Dim i As Long
    Dim rowOut As Long
    Dim linea As Object
    Dim dirCol As Collection

    ws.Range("I13").Value = dataFactura("numFactura")
    ws.Range("I14").Value = dataFactura("fechaFactura")
    ws.Range("I15").Value = dataFactura("personaContacto")
    ws.Range("I16").Value = dataFactura("unidadTienda")
    'I17 no se toca (30 DIAS fijo)
    ws.Range("I18").Value = dataFactura("fechaVencimiento")
    ws.Range("I19").Value = dataFactura("fechaEntrega")
    ws.Range("I20").Value = dataFactura("referenciaCliente")

    ws.Range("B19:B23").ClearContents
    Set dirCol = infoEntrega("direccion")
    For i = 1 To WorksheetFunction.Min(5, dirCol.Count)
        ws.Range("B18").Offset(i, 0).Value = dirCol(i)
    Next i

    ws.Range("B25:I63").ClearContents
    rowOut = 25
    For i = 1 To dataFactura("lineas").Count
        If i > MAX_LINEAS Then Exit For
        Set linea = dataFactura("lineas")(i)
        ws.Cells(rowOut, "B").Value = linea("cantidad")
        ws.Cells(rowOut, "C").Value = linea("precioUnitario")
        ws.Cells(rowOut, "D").Value = linea("descripcion")
        ws.Cells(rowOut, "F").Value = linea("base")
        ws.Cells(rowOut, "G").Value = 21
        ws.Cells(rowOut, "H").Value = linea("ivaImporte")
        ws.Cells(rowOut, "I").Value = linea("totalLinea")
        rowOut = rowOut + 1
    Next i

    ws.Range("I64").Value = dataFactura("baseTotal")
    ws.Range("I65").Value = dataFactura("ivaTotal")
    ws.Range("I66").Value = 0
    ws.Range("I68").Value = dataFactura("totalFactura")
End Sub

Private Sub AjustarIVAUltimaLinea(ByVal lineas As Collection, ByVal ivaTotalSAP As Double)
    Dim sumaIVA As Double
    Dim i As Long
    Dim diff As Double
    Dim ultima As Object

    If lineas.Count = 0 Or ivaTotalSAP = 0 Then Exit Sub

    For i = 1 To lineas.Count
        sumaIVA = sumaIVA + CDbl(lineas(i)("ivaImporte"))
    Next i

    diff = Round(ivaTotalSAP - sumaIVA, 2)
    If Abs(diff) >= 0.01 Then
        Set ultima = lineas(lineas.Count)
        ultima("ivaImporte") = Round(CDbl(ultima("ivaImporte")) + diff, 2)
        ultima("totalLinea") = Round(CDbl(ultima("base")) + CDbl(ultima("ivaImporte")), 2)
    End If
End Sub

Private Function ExtraerTextoPDF_Word(ByVal rutaPdf As String, ByVal wordApp As Object) As String
    Dim doc As Object
    On Error GoTo ErrHandler

    Set doc = wordApp.Documents.Open(FileName:=rutaPdf, ConfirmConversions:=False, ReadOnly:=True, AddToRecentFiles:=False)
    ExtraerTextoPDF_Word = doc.Content.Text
    doc.Close False
    Exit Function

ErrHandler:
    On Error Resume Next
    If Not doc Is Nothing Then doc.Close False
    Err.Raise vbObjectError + 1201, , "Error extrayendo texto con Word: " & Err.Description
End Function

Private Function SeleccionarCarpeta(ByVal titulo As String) As String
    Dim fd As FileDialog
    Set fd = Application.FileDialog(FOLDER_PICKER)
    With fd
        .Title = titulo
        .AllowMultiSelect = False
        If .Show <> -1 Then Exit Function
        SeleccionarCarpeta = .SelectedItems(1)
    End With
End Function

Private Function AgregarBarra(ByVal p As String) As String
    If Right$(p, 1) = "\" Then
        AgregarBarra = p
    Else
        AgregarBarra = p & "\"
    End If
End Function

Private Sub AnexarLog(ByVal logPath As String, ByVal texto As String)
    Dim f As Integer
    f = FreeFile
    Open logPath For Append As #f
    Print #f, Format(Now, "yyyy-mm-dd hh:nn:ss") & " | " & texto
    Close #f
End Sub

Private Function ValorBooleano(ByVal v As Variant) As Boolean
    Dim s As String
    If VarType(v) = vbBoolean Then
        ValorBooleano = CBool(v)
    Else
        s = UCase$(Trim$(CStr(v)))
        ValorBooleano = (s = "TRUE" Or s = "VERDADERO" Or s = "1" Or s = "SI" Or s = "SÍ")
    End If
End Function

Private Function ExtraerNumeroFactura(ByVal txt As String) As String
    Dim rgx As Object
    Dim mc As Object

    Set rgx = CreateObject("VBScript.RegExp")
    rgx.IgnoreCase = True
    rgx.Global = False
    rgx.Pattern = "(?:Factura\s*(?:n[ºo°.]*)?\s*[:\-]?\s*)([A-Z0-9\-/]+)"

    If rgx.Test(txt) Then
        Set mc = rgx.Execute(txt)
        ExtraerNumeroFactura = Trim$(mc(0).SubMatches(0))
        Exit Function
    End If

    rgx.Pattern = "\b\d{8,}\b"
    If rgx.Test(txt) Then
        Set mc = rgx.Execute(txt)
        ExtraerNumeroFactura = Trim$(mc(0).Value)
    End If
End Function

Private Function ExtraerReferenciaCliente(ByVal txt As String) As String
    ExtraerReferenciaCliente = ExtraerValorTrasEtiqueta(txt, Array("Referencia del cliente", "Nº pedido", "Numero de pedido", "Pedido cliente"))
End Function

Private Function ExtraerValorTrasEtiqueta(ByVal txt As String, ByVal etiquetas As Variant) As String
    Dim arr() As String
    Dim i As Long, k As Long
    Dim pos As Long
    Dim e As String
    Dim ln As String

    arr = Split(NormalizarSaltos(txt), vbLf)
    For i = LBound(arr) To UBound(arr)
        ln = arr(i)
        For k = LBound(etiquetas) To UBound(etiquetas)
            e = CStr(etiquetas(k))
            pos = InStr(1, ln, e, vbTextCompare)
            If pos > 0 Then
                Dim cola As String
                cola = Mid$(ln, pos + Len(e))
                cola = Replace(cola, ":", "")
                cola = Trim$(cola)
                If Len(cola) > 0 Then
                    ExtraerValorTrasEtiqueta = cola
                    Exit Function
                ElseIf i + 1 <= UBound(arr) Then
                    ExtraerValorTrasEtiqueta = Trim$(arr(i + 1))
                    Exit Function
                End If
            End If
        Next k
    Next i
End Function

Private Function ExtraerFechaTrasEtiqueta(ByVal txt As String, ByVal etiqueta As String) As String
    Dim arr() As String
    Dim i As Long
    Dim ln As String
    Dim f As String

    arr = Split(NormalizarSaltos(txt), vbLf)
    For i = LBound(arr) To UBound(arr)
        ln = arr(i)
        If InStr(1, ln, etiqueta, vbTextCompare) > 0 Then
            f = ExtraerPrimeraFecha(ln)
            If Len(f) = 0 And i + 1 <= UBound(arr) Then f = ExtraerPrimeraFecha(arr(i + 1))
            If Len(f) > 0 Then
                ExtraerFechaTrasEtiqueta = f
                Exit Function
            End If
        End If
    Next i
End Function

Private Function ExtraerPrimeraFecha(ByVal txt As String) As String
    Dim rgx As Object
    Dim mc As Object

    Set rgx = CreateObject("VBScript.RegExp")
    rgx.Global = False
    rgx.Pattern = "\b(\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})\b"

    If rgx.Test(txt) Then
        Set mc = rgx.Execute(txt)
        ExtraerPrimeraFecha = Replace(mc(0).Value, "-", "/")
    End If
End Function

Private Function TryParseFecha(ByVal s As String, ByRef outDate As Date) As Boolean
    On Error GoTo ErrHandler
    Dim p() As String
    s = Replace(s, "-", "/")
    p = Split(s, "/")
    If UBound(p) = 2 Then
        outDate = DateSerial(CInt(p(2)), CInt(p(1)), CInt(p(0)))
        TryParseFecha = True
    End If
    Exit Function
ErrHandler:
    TryParseFecha = False
End Function

Private Function BuscarPdfAlbaran(ByVal carpeta As String, ByVal numero As String) As String
    Dim f As String
    f = Dir(AgregarBarra(carpeta) & "*" & numero & "*.pdf")
    If Len(f) > 0 Then
        BuscarPdfAlbaran = AgregarBarra(carpeta) & f
    End If
End Function

Private Function NormalizarNumeroAlbaran(ByVal s As String) As String
    s = Replace(s, ".", "")
    s = Replace(s, " ", "")
    NormalizarNumeroAlbaran = s
End Function

Private Function NormalizarSaltos(ByVal txt As String) As String
    txt = Replace(txt, vbCrLf, vbLf)
    txt = Replace(txt, vbCr, vbLf)
    NormalizarSaltos = txt
End Function

Private Function ExtraerImportesLinea(ByVal ln As String) As Collection
    Dim c As New Collection
    Dim rgx As Object
    Dim mc As Object
    Dim m As Object

    Set rgx = CreateObject("VBScript.RegExp")
    rgx.Global = True
    rgx.Pattern = "\d{1,3}(?:\.\d{3})*,\d{2}"

    If rgx.Test(ln) Then
        Set mc = rgx.Execute(ln)
        For Each m In mc
            c.Add ImporteEspanolADouble(CStr(m.Value))
        Next m
    End If

    Set ExtraerImportesLinea = c
End Function

Private Function ImporteEspanolADouble(ByVal s As String) As Double
    s = Replace(s, ".", "")
    s = Replace(s, ",", ".")
    ImporteEspanolADouble = CDbl(Val(s))
End Function

Private Function TieneImporteEspanol(ByVal s As String) As Boolean
    Dim rgx As Object
    Set rgx = CreateObject("VBScript.RegExp")
    rgx.Pattern = "\d{1,3}(?:\.\d{3})*,\d{2}"
    TieneImporteEspanol = rgx.Test(s)
End Function

Private Function LimpiarDescripcion(ByVal texto As String, ByVal nums As Collection) As String
    Dim i As Long
    Dim tmp As String
    tmp = texto
    For i = 1 To nums.Count
        tmp = Replace(tmp, FormatoImporte(nums(i)), "")
    Next i
    LimpiarDescripcion = Trim$(tmp)
End Function

Private Function FormatoImporte(ByVal d As Double) As String
    Dim s As String
    s = Format(d, "#,##0.00")
    s = Replace(s, ",", "|")
    s = Replace(s, ".", ",")
    s = Replace(s, "|", ".")
    FormatoImporte = s
End Function

Private Function ExtraerUltimoImporte(ByVal txt As String) As Double
    Dim nums As Collection
    Set nums = ExtraerImportesLinea(txt)
    If nums.Count > 0 Then ExtraerUltimoImporte = CDbl(nums(nums.Count))
End Function

Private Function InferirUnidadDesdeDireccion(ByVal dir As Collection) As String
    Dim i As Long
    Dim l As String
    For i = 1 To dir.Count
        l = dir(i)
        If InStr(l, "-") > 0 Then
            InferirUnidadDesdeDireccion = Trim$(l)
            Exit Function
        End If
    Next i
End Function

Private Sub CopiarCollection(ByVal origen As Collection, ByVal destino As Collection)
    Dim v As Variant
    For Each v In origen
        destino.Add v
    Next v
End Sub

Private Function LimpiarNombreArchivo(ByVal s As String) As String
    Dim invalidos As Variant
    Dim i As Long
    invalidos = Array("\\", "/", ":", "*", "?", Chr$(34), "<", ">", "|")
    For i = LBound(invalidos) To UBound(invalidos)
        s = Replace(s, invalidos(i), "_")
    Next i
    LimpiarNombreArchivo = Trim$(s)
End Function
