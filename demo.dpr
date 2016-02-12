program demo;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  LuaEngine in 'LuaEngine.pas',
  Lua in 'Lua.pas';

procedure hello(const Context: TLuaFunctionContext);
var
  i: Integer;
begin
  for i := 0 to Context.ArgumentsCount - 1 do
    WriteLn(Context.Arguments[i].AsString);
  Context.PushResult('Hello');
  Context.PushResult(Pi);
end;

var lua: TLuaEngine;

begin
  try
    lua := TLuaEngine.Create;
    lua.RegisterFunction('hello', hello);
    lua.RunCode('print("## Lua script started"); print(hello(1, "qwer"));');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
