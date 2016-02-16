unit Lua.StandartModules;

interface

uses
  LuaLib, Lua.Types;

type
  LuaModule = class(TInterfacedObject, ILuaExtension)
  protected
    FFunction: TLuaCFunction;
    constructor Create(const AFunction: TLuaCFunction);
  protected
    // ILuaExtension
    function ShouldBeSaved: LongBool; stdcall;
    procedure Register(const AHandle: TLuaState); stdcall;
  public
    class function Base: ILuaExtension; static;
    class function Debug: ILuaExtension; static;
    class function IO: ILuaExtension; static;
    class function Math: ILuaExtension; static;
    class function OS: ILuaExtension; static;
    class function Packages: ILuaExtension; static;
    class function Strings: ILuaExtension; static;
    class function Table: ILuaExtension; static;
    class function All: ILuaExtension; static;
  end;

implementation

const
  LUA_ALL_MODULES = Pointer(-1);

{ LuaLibrary }

constructor LuaModule.Create(const AFunction: TLuaCFunction);
begin
  FFunction := AFunction;
end;

procedure LuaModule.Register(const AHandle: TLuaState);
begin
  if Assigned(AHandle) and Assigned(FFunction) then
  begin
    if @FFunction <> LUA_ALL_MODULES then
    begin
      lua_pushcfunction(AHandle, FFunction);
      lua_call(AHandle, 0, 0);
    end else
    begin
      luaL_openlibs(AHandle);
    end;
  end;
end;

class function LuaModule.All: ILuaExtension;
begin
  Result := LuaModule.Create(LUA_ALL_MODULES);
end;

class function LuaModule.Base: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_base);
end;

class function LuaModule.Debug: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_debug);
end;

class function LuaModule.IO: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_io);
end;

class function LuaModule.Math: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_math);
end;

class function LuaModule.OS: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_os);
end;

class function LuaModule.Packages: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_package);
end;

function LuaModule.ShouldBeSaved: LongBool;
begin
  Result := false;
end;

class function LuaModule.Strings: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_string);
end;

class function LuaModule.Table: ILuaExtension;
begin
  Result := LuaModule.Create(luaopen_table);
end;

end.
