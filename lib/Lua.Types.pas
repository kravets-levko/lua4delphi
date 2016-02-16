unit Lua.Types;

interface

uses
  SysUtils, LuaLib;

type
  TLuaState = lua_State;
  TLuaCFunction = lua_CFunction;

type
  ELuaException = class(Exception)
  public
    constructor Create(const ErrorCode: Integer; const LuaState: TLuaState); overload; virtual;
  end;

  ILuaExtension = interface(IInterface)
  ['{8C6C363F-3D7F-49E4-932D-A8FA8401562C}']
    // Return TRUE if you need to keep your object alive
    // until TLuaCore object will be destroyed
    function ShouldBeSaved: LongBool; stdcall;
    // Payload
    procedure Register(const AHandle: TLuaState); stdcall;
  end;

procedure LuaCheck(const ErrorCode: Integer; const LuaState: TLuaState);

implementation

resourcestring
  sLuaUnknownError = 'Unknown error';
  sLuaFailedToRun = 'Failed to execute code';
  sLuaFailedToLoadFile = 'Failed to load file';
  sLuaOutOfMemory = 'Out of memory';
  sLuaErrorHandlerRunning = 'Error handler is already running';
  sLuaSyntaxError = 'Syntax error';

procedure LuaCheck(const ErrorCode: Integer; const LuaState: TLuaState);
begin
  if ErrorCode <> 0 then
    raise ELuaException.Create(ErrorCode, LuaState);
end;

{ ELuaException }

constructor ELuaException.Create(const ErrorCode: Integer; const LuaState: TLuaState);
var
  msgOnStack: Boolean;
  msg: string;
begin
  msgOnStack := true;
  case ErrorCode of
    LUA_ERRRUN: msg := sLuaFailedToRun;
    LUA_ERRSYNTAX: msg := sLuaSyntaxError;
    LUA_ERRMEM: begin
      msg := sLuaOutOfMemory;
      msgOnStack := false;
    end;
    LUA_ERRERR: msg := sLuaErrorHandlerRunning;
    LUA_ERRFILE: msg := sLuaFailedToLoadFile;
    else msg := sLuaUnknownError;
  end;

  if msgOnStack then
  begin
    if Assigned(LuaState) then
    begin
      if lua_gettop(LuaState) > 0 then
        msg := msg + ': ' + string(AnsiString(lua_tostring(LuaState, -1)));
    end;
  end;

  Create(msg);
end;

end.
