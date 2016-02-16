unit Lua.UserFunction;

interface

uses
  LuaLib, Lua.Types;

type
  TLuaUserFunctionPrototype = reference to procedure(const AHandle: TLuaState;
    out CountOfResults: Integer);

  TLuaUserFunction = class(TInterfacedObject, ILuaExtension)
  protected
    FName: string;
    FFunction: TLuaUserFunctionPrototype;
  protected
    // ILuaExtension
    function ShouldBeSaved: LongBool; stdcall;
    procedure Register(const AHandle: TLuaState); stdcall;
  public
    constructor Create(const AName: string;
      const AFunction: TLuaUserFunctionPrototype); virtual;

    function Invoke(const AHandle: TLuaState): Integer; virtual;
  end;

implementation

uses
  SysUtils;

// This function is called by Lua, it extracts the object by
// pointer to the objects method by name, which is then called.
function LuaCallBack(AState: TLuaState): Integer; cdecl;
var
  CallBack: TLuaUserFunction; // The Object stored in the Object Table
begin
  Result := 0;

  // Retrieve first Closure Value (=Object Pointer)
  CallBack := lua_topointer(AState, lua_upvalueindex(1));

  // Execute only if Object is valid
  if Assigned(CallBack) then
  try
    Result := CallBack.Invoke(AState);
  except
    // Catch an error
    on E: Exception do
      Result := luaL_error(AState, PAnsiChar(AnsiString(
        'Unhandled exception ' + E.ClassName + ': ' + E.Message)), []);
  end;
end;

{ TUserFunction }

constructor TLuaUserFunction.Create(const AName: string;
  const AFunction: TLuaUserFunctionPrototype);
begin
  FName := AName;
  FFunction := AFunction;
end;

function TLuaUserFunction.Invoke(const AHandle: TLuaState): Integer;
begin
  Result := 0;
  if Assigned(FFunction) and Assigned(AHandle) then
  begin
    FFunction(AHandle, Result);
    if Result < 0 then
      Result := 0;
  end;
end;

procedure TLuaUserFunction.Register(const AHandle: TLuaState);
begin
  if Assigned(AHandle) and Assigned(FFunction) and (FName <> '') then
  begin
    // prepare Closure value (Method Name)
    lua_pushstring(AHandle, PAnsiChar(AnsiString(FName)));

    // prepare Closure value (Self object)
    lua_pushlightuserdata(AHandle, Pointer(Self));

    // set new Lua function with Closure value
    lua_pushcclosure(AHandle, LuaCallBack, 1);
    lua_settable(AHandle, LUA_GLOBALSINDEX);
  end;
end;

function TLuaUserFunction.ShouldBeSaved: LongBool;
begin
  Result := true;
end;

end.
