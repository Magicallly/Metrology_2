unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Code: TMemo;
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    OpenDialog1: TOpenDialog;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
   PCodeStr = ^TCodeStr;
   TCodeStr = record
                 CodeStr: string[255];
                 pNextStr: PCodeStr;
              end;
   TStatements = (stNull, stIf, stFor, stWhile, stDo, stWhen);

var
  codeStr, FILE_NAME: string;
  CLI, CL, StatementCount: Integer;
  rCL: Real;

procedure ToFormCodeString(var ReqStr: string);
var
  CurF: TextFile;
  CurStr: string;
begin
  ReqStr:='';

  AssignFile(CurF, FILE_NAME);
  Reset(CurF);
  Readln(CurF, CurStr);
  reqStr:=CurStr+#13#10;
  while not(eof(CurF)) do
  begin
    Readln(CurF,CurStr);
    CurStr:=CurStr+#13#10;
    reqStr:=ReqStr+CurStr;
  end;
  close(Curf);
end;

procedure ReadCodeStr(var pBegin, pEnd: PCodeStr);
var
   pTempStr: PCodeStr;
   CodeStr: string[225];
   CodeFile: TextFile;
begin
   pBegin := nil;
   pEnd := nil;
   AssignFile(CodeFile, FILE_NAME);
   Reset(CodeFile);
   while not Eof(CodeFile) do
   begin
      Readln(CodeFile, CodeStr);
      New(pTempStr);
      pTempStr^.CodeStr := CodeStr;
      pTempStr^.pNextStr := nil;
      if pBegin = nil then
         pBegin := pTempStr
      else
         pEnd^.pNextStr := pTempStr;
      pEnd := pTempStr;
   end;
   CloseFile(CodeFile);
end;

procedure CalculateJilb(var pCurrStr: PCodeStr; var CL, MaxCLI: Integer;
                        CLI, OpenBracelCount: Integer; CurrStatement: TStatements);
var
   CodeStr: string[255];
   IsIfEnd: Boolean;
   NextStatement: TStatements;
   OBracelCount, BranchesCount: Integer;
begin
   IsIfEnd := False;
   repeat
      CodeStr := pCurrStr^.CodeStr;
      pCurrStr := pCurrStr^.pNextStr;
      NextStatement := stNull;
      if (Pos('if', CodeStr) > 0) then
         NextStatement := stIf;
      if (Pos('for', CodeStr) > 0) then
         NextStatement := stFor;
      if (Pos('while', CodeStr) > 0) then
         NextStatement := stWhile;
      if (Pos('do', CodeStr) > 0) then
         NextStatement := stDo;
      if NextStatement <> stNull then
      begin
         Inc(CL);
         if Pos('{', CodeStr) > 0 then
            CalculateJilb(pCurrStr, CL, MaxCLI, CLI + 1, 0, NextStatement)
         else
            CalculateJilb(pCurrStr, CL, MaxCLI, CLI + 1, -1, NextStatement);
      end
      else
         if Pos('when', CodeStr) > 0 then
         begin
            OBracelCount := 0;
            BranchesCount := 0;
            repeat
               CodeStr := pCurrStr^.CodeStr;
               pCurrStr := pCurrStr^.pNextStr;
               if (Pos('->', CodeStr) > 0) then
               begin
                  if Pos('else', CodeStr) = 0 then
                  begin
                     Inc(BranchesCount);
                     Inc(CL);
                  end;
                  if Pos('{', CodeStr) > 0 then
                     CalculateJilb(pCurrStr, CL, MaxCLI, CLI + BranchesCount, 0, stWhen)
                  else
                     CalculateJilb(pCurrStr, CL, MaxCLI, CLI + BranchesCount, -1, stWhen);
               end;
               if Pos('{', CodeStr) > 0 then
                  Inc(OBracelCount);
               if Pos('}', CodeStr) > 0 then
                  Dec(OBracelCount);
            until OBracelCount = -1;
         end
         else
         begin
             if Pos('{', CodeStr) > 0 then
                Inc(OpenBracelCount);
             if Pos('}', CodeStr) > 0 then
                Dec(OpenBracelCount);
             if OpenBracelCount = -1 then
             begin
                CodeStr := pCurrStr^.CodeStr;
                if (Pos('else', CodeStr) > 0) and (CurrStatement = stIf) then
                begin
                   pCurrStr := pCurrStr^.pNextStr;
                   if Pos('{', CodeStr) > 0 then
                      Inc(OpenBracelCount);
                end
                else
                begin
                   if (CurrStatement = stDo) then
                      pCurrStr := pCurrStr^.pNextStr;
                   IsIfEnd := True;
                end;
             end;
         end;
   until (pCurrStr = nil) or IsIfEnd;
   if CLI > MaxCLI then
      MaxCLI := CLI;
end;

function CountStatements: Integer;
const
   Statements: array [1..43] of string[8] = ('-', '+', '*', '/', '%', '=', '-=',
    '+=', '*=', '/=', '%=', '--', '++', '&&', '||', '!', '==', '!=', '>', '<',
    '>=', '<=', '!!', '?.', '?:', '::', '..', '?', '@',
     '$', '===', 'if', '->','while', 'for', 'return','repeat',
    'break', 'continue', 'goto','with','print','println');
var
   i, Count: Integer;
   UserFile: TextFile;
   CodeStr: string[255];
   TempStr: string;
begin
   AssignFile(UserFile, FILE_NAME);
   Reset(UserFile);
   Count := 0;
   while not Eof(UserFile) do
   begin
      Readln(UserFile, CodeStr);
      for i := 1 to Length(Statements) do
         if Pos(Statements[i], CodeStr) > 0 then
         begin
            if (Statements[i] = '->') or (Statements[i] = '+=') or (Statements[i] = '-=') or (Statements[i] = '*=') then
              Dec(Count,2);
            if Not(Statements[i] = '==') then
              Inc(Count);
         end;
   end;
   CloseFile(UserFile);
   CountStatements := Count;
end;

procedure Main;
var
   pBegin, pEnd, pCurrStr: PCodeStr;
begin
   StatementCount := CountStatements;
   ReadCodeStr(pBegin, pEnd);
   pCurrStr := pBegin;
   CLI := -1;
   CL := 0;
   CalculateJilb(pCurrStr, CL, CLI, -1, 0, stNull);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    begin
      FILE_NAME := OpenDialog1.FileName;
      ToFormCodeString(CodeStr);
    end;
  Code.Text := CodeStr;
  Main;
  Label1.Caption := Label1.Caption + IntToStr(CL);
  rCL := CL / StatementCount;
  Label2.Caption := Label2.Caption + FloatToStr(rCL);
  Label3.Caption := Label3.Caption + IntToStr(CLI);
  Label4.Caption := Label4.Caption + IntToStr(StatementCount);
end;

end.
