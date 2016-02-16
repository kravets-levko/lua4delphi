unit Lua.GlobalVariable;

interface

uses
  LuaLib, Lua.Types;

type
  TLuaGlobalVariable = class(TInterfacedObject, ILuaExtension)
  protected
    FName: string;
    FType: (
      TypeNil,
      TypeBoolean,
      TypeInteger,
      TypeDouble,
      TypeString,
      TypeData
    );

    FBoolean: Boolean;
    FInteger: Integer;
    FDouble: Double;
    FString: RawByteString;
    FData: Pointer;
    FDataSize: Integer;
  protected
    // ILuaExtension
    function ShouldBeSaved: LongBool; stdcall;
    procedure Register(const AHandle: TLuaState); stdcall;
  public
    constructor Create(const AName: string); overload; virtual;
    constructor Create(const AName: string; const Value: Boolean); overload; virtual;
    constructor Create(const AName: string; const Value: Integer); overload; virtual;
    constructor Create(const AName: string; const Value: Double); overload; virtual;
    constructor Create(const AName: string; const Value: RawByteString); overload; virtual;
    constructor Create(const AName: string; const Data: Pointer; const DataSize: Integer); overload; virtual;
  end;

implementation

{ TLuaGlobalVariable }

constructor TLuaGlobalVariable.Create(const AName: string; const Value: Integer);
begin
  FName := AName;
  FType := TypeInteger;
  FInteger := Value;
end;

constructor TLuaGlobalVariable.Create(const AName: string; const Value: Boolean);
begin
  FName := AName;
  FType := TypeBoolean;
  FBoolean := Value;
end;

constructor TLuaGlobalVariable.Create(const AName: string; const Value: Double);
begin
  FName := AName;
  FType := TypeDouble;
  FDouble := Value;
end;

constructor TLuaGlobalVariable.Create(const AName: string; const Data: Pointer; const DataSize: Integer);
begin
  FName := AName;
  FType := TypeData;
  FData := Data;
  FDataSize := DataSize;
  if FDataSize < 0 then
    FDataSize := 0;
end;

constructor TLuaGlobalVariable.Create(const AName: string);
begin
  FName := AName;
  FType := TypeNil;
end;

constructor TLuaGlobalVariable.Create(const AName: string; const Value: RawByteString);
begin
  FName := AName;
  FType := TypeString;
  FString := Value;
end;

procedure TLuaGlobalVariable.Register(const AHandle: TLuaState);
begin
  if Assigned(AHandle) and (FName <> '') then
  begin
    case FType of
      TypeNil: lua_pushnil(AHandle);
      TypeBoolean: lua_pushboolean(AHandle, FBoolean);
      TypeInteger: lua_pushinteger(AHandle, FInteger);
      TypeDouble: lua_pushnumber(AHandle, FDouble);
      TypeString: lua_pushlstring(AHandle, PAnsiChar(FString), Length(FString));
      TypeData: begin
        if Assigned(FData) then lua_pushlstring(AHandle, PAnsiChar(FData), FDataSize)
          else lua_pushnil(AHandle);
      end;
    end;
    lua_setglobal(AHandle, PAnsiChar(AnsiString(FName)));
  end;
end;

function TLuaGlobalVariable.ShouldBeSaved: LongBool;
begin
  Result := false;
end;

end.
