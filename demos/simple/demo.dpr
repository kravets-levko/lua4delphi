program demo;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  LuaLib in '..\..\api\LuaLib.pas',
  Lua.Core in '..\..\lib\Lua.Core.pas',
  Lua.GlobalVariable in '..\..\lib\Lua.GlobalVariable.pas',
  Lua.Stack in '..\..\lib\Lua.Stack.pas',
  Lua.StandartModules in '..\..\lib\Lua.StandartModules.pas',
  Lua.Types in '..\..\lib\Lua.Types.pas',
  Lua.UserFunction in '..\..\lib\Lua.UserFunction.pas';

var
  lua: TLuaCore;

begin
  try
    lua := TLuaCore.Create();

    // Modules
    lua.RegisterExtension(LuaModule.Base);
    lua.RegisterExtension(LuaModule.Math);

    // Global variables
    lua.RegisterExtension(TLuaGlobalVariable.Create('greeting', 'Hello, World'));
    lua.RegisterExtension(TLuaGlobalVariable.Create('sqrt2', Sqrt(2)));

    // Global functions
    lua.RegisterExtension(TLuaUserFunction.Create(
      'hello',
      procedure(const AHandle: TLuaState; out CountOfResults: Integer)
      begin
        lua_pushstring(AHandle, 'Greeting from callback');
        lua_pushnumber(AHandle, Pi);
        CountOfResults := 2;
      end
    ));

    lua.RunCode(
      'print("## Lua script started");'#13#10 +
      'print(greeting, sqrt2);'#13#10 +
      'print(math.pi);'#13#10 +
      'print(hello(math.pi, "qwer"));'#13#10
    );
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
