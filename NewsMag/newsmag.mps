// NEWSMAG.MPS: This is just a minimal modification to the original
//              ONLYONCE.MPS by g00r00 included with MysticBBS
//
// Usage:
//    Menu command: GX
//            Data: newsmag news
//
// The above example will display news.XXX from current text directory
// only if it has been updated since the users last login

Uses
  CFG,
  USER;
  
Var
  FN : String;
Begin
  GetThisUser;

  FN := JustFileName(ParamStr(1));

  If Pos(PathChar, ParamStr(1)) = 0 Then
    FN := CfgTextPath + FN;

  FindFirst (FN + '.*', 0);

  While DosError = 0 Do Begin
    If DirTime > UserLastOn Then Begin
      DispFile(FN);
      WriteLn( '|CR|PA' );
      Break;
    End;

    FindNext
  End;

  FindClose;
End.
