unit UManipulaWord;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Phys, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Stan.Pool, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait,
  System.Win.ComObj;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    edContrato: TEdit;
    edData: TEdit;
    Label3: TLabel;
    edGrupo: TEdit;
    Button1: TButton;
    Label4: TLabel;
    edArquivo: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    edNumRef: TEdit;
    edCliente: TEdit;
    Label7: TLabel;
    edCredito: TEdit;
    Label8: TLabel;
    edModelo: TEdit;
    FDQuery1: TFDQuery;
    Button2: TButton;
    edDocumento: TEdit;
    Label9: TLabel;
    OpenDialog: TOpenDialog;
    FDConnection1: TFDConnection;
    Button3: TButton;
    SaveDialog: TSaveDialog;
    ckPDF: TCheckBox;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    WrdApp: Variant;
    procedure ConvertDocToPdf(arquivo : String);
    Procedure FindAndReplace(Find,Replace:String);
  public
    procedure TrocaHeader(doc : OleVariant);
  end;

var
  Form1: TForm1;

implementation



{$R *.dfm}

Procedure TForm1.FindAndReplace(Find,Replace:String);
const
  wdReplaceAll = 2;
  wdFindContinue = 1;
  wdReplaceOne = 1;
Begin
      //Initialize parameters
  WrdApp.Selection.Find.ClearFormatting;
  WrdApp.Selection.Find.Text := Find;
  WrdApp.Selection.Find.Replacement.Text := Replace;
  WrdApp.Selection.Find.Forward := True;
  WrdApp.Selection.Find.Wrap := wdFindContinue;
  WrdApp.Selection.Find.Format := False;
  WrdApp.Selection.Find.MatchCase :=  False;
  //WrdApp.Selection.Find.MatchWholeWord := wrfMatchCase in Flags;
 // WrdApp.Selection.Find.MatchWildcards :=wrfMatchWildcards in Flags;
  WrdApp.Selection.Find.MatchSoundsLike := False;
  WrdApp.Selection.Find.MatchAllWordForms := False;
     { Perform the search}
  //if wrfReplaceAll in Flags then
   WrdApp.Selection.Find.Execute(Replace := wdReplaceAll)
  {else
   WrdApp.Selection.Find.Execute(Replace := wdReplaceOne);}
End;

procedure TForm1.Button1Click(Sender: TObject);
var
  WordApp: Variant;
  Documento, pdf: Olevariant;
begin
  WordApp:= CreateOleObject('Word.Application');
  try
    WordApp.Visible := False;
    Documento := WordApp.Documents.Open('C:\Source\Livre\ContratoEntregaAlienacao.v1.docx');

    Documento.Content.Find.Execute(FindText := '[CONTRATO]', ReplaceWith := edContrato.Text);
    Documento.Content.Find.Execute(FindText := '[DTCO]', ReplaceWith := edData.Text);
    Documento.Content.Find.Execute(FindText := '[GRUPO]', ReplaceWith := edGrupo.Text);
    Documento.Content.Find.Execute(FindText := '[NUMREF]', ReplaceWith := edNumRef.Text);
    Documento.Content.Find.Execute(FindText := '[CLIENTE]', ReplaceWith := edCliente.Text);
    Documento.Content.Find.Execute(FindText := '[CREDITO]', ReplaceWith := edCredito.Text);
    Documento.Content.Find.Execute(FindText := '[BEM]', ReplaceWith := edModelo.Text);
    TrocaHeader(documento);
    Documento.SaveAs(edArquivo.text);
  finally
    WordApp.Quit;
  end;
  ConvertDocToPdf(edArquivo.text);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    with FDQuery1.SQL do
    begin
      Clear;
      Add('insert into CP_DOC_WORD');
      Add(' (id, documento, arquivo, user_cad)');
      Add('values');
      Add(' (gen_id(GN_CP_DOC_WORD,1), :documento, :arquivo, :user_cad)');
    end;
    with FDQuery1 do
    begin
      ParamByName('arquivo').DataType := ftOraBlob;
      ParamByName('arquivo').LoadFromFile(OpenDialog.FileName, ftOraBlob);
      //ParamByName('xml').AsStream := TStringStream.Create(xml, TEncoding.UTF8);
      ParamByName('documento').AsString := edDocumento.Text;
      ParamByName('user_cad').AsInteger := -1;
    end;
    FDQuery1.ExecSQL;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  FDQuery1.Open('select * from CP_DOC_WORD');
  FDQuery1.First;
  while not FDQuery1.Eof do
  begin
    if SaveDialog.Execute then
      TBlobField(FDQuery1.FieldByName('arquivo')).SaveToFile(SaveDialog.FileName);
    FDQuery1.Next;
  end;

end;

procedure TForm1.Button4Click(Sender: TObject);
const
  wdFirstPageHeaderStory = 10;
  wdFirstPageFooterStory=11;
  wdMainTextStory=1;
  wdFindContinue=1;
  wdReplaceAll=2;

var
  SearchRng: OleVariant;
  Story : integer;//wdStoryType;
  Word, Doc: OleVariant;
begin
   WrdApp:= CreateOleObject('Word.Application');
  try
    WrdApp.Visible := False;
    doc := WrdApp.Documents.Open('C:\Source\Livre\COPIA\novo3.doc');
    for Story := wdMainTextStory to wdFirstPageFooterStory do
    begin
      try
        SearchRng := Doc.StoryRanges.Item(Story);
        SearchRng.Find.Execute('[CONTRATO]',
                        Wrap := wdFindContinue,
                        ReplaceWith := edContrato.Text,
                        Replace := wdReplaceAll);
      except
        on E: EOleSysError do
        begin { Curse MS for this stupid collection } end;
      end;
    end;
    Doc.SaveAs(edArquivo.text);
  finally
    WrdApp.Quit;
  end;
end;

procedure TForm1.ConvertDocToPdf(arquivo: String);
var
  Word, Doc: OleVariant;
begin
  try
    Word := CreateOLEObject('Word.Application');
    Doc := Word.Documents.Open(arquivo);
    Doc.ExportAsFixedFormat('c:\temp\arquivo.pdf', 17);
  finally
    word.quit;
  end;
end;


procedure TForm1.TrocaHeader(doc: OleVariant);
const
  wdFirstPageHeaderStory = 10;
  wdFirstPageFooterStory=11;
  wdMainTextStory=1;
  wdFindContinue=1;
  wdReplaceAll=2;
var
  SearchRng: OleVariant;
  Story : integer;//wdStoryType;
begin
  for Story := wdMainTextStory to wdFirstPageFooterStory do
  begin
    try
      SearchRng := Doc.StoryRanges.Item(Story);
      SearchRng.Find.Execute('[CONTRATO]',
                      Wrap := wdFindContinue,
                      ReplaceWith := edContrato.Text,
                      Replace := wdReplaceAll);
    except
      on E: EOleSysError do
      begin { Curse MS for this stupid collection } end;
    end;
  end;
end;

end.