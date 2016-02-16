unit Lua.Core;

interface

uses
  LuaLib, Lua.Types;

type
  TLuaCore = class(TObject)
  protected
    FHandle: TLuaState;
    FOwnHandle: Boolean;
    FOwnedObjects: TArray<IInterface>;
    procedure HandleNeeded; virtual;
    procedure DestroyHandle; virtual;
    function GetHandle: TLuaState;
    procedure SetHandle(const Value: TLuaState);
  public
    property Handle: TLuaState read GetHandle write SetHandle;
    property OwnHandle: Boolean read FOwnHandle write FOwnHandle;

    constructor Create; overload; virtual;
    constructor Create(const AHandle: TLuaState; OwnHandle: Boolean = false); overload; virtual;
    destructor Destroy; override;

    procedure RunCode(const ACode: string);
    procedure RunFile(const AFileName: string);

    procedure RegisterExtension(AnExtension: ILuaExtension);
  end;

implementation

{ TLuaCore }

constructor TLuaCore.Create;
begin
  FHandle := nil;
  FOwnHandle := true;
end;

constructor TLuaCore.Create(const AHandle: TLuaState; OwnHandle: Boolean);
begin
  FHandle := AHandle;
  FOwnHandle := OwnHandle;
end;

destructor TLuaCore.Destroy;
begin
  DestroyHandle;
  inherited;
end;

procedure TLuaCore.HandleNeeded;
begin
  if not Assigned(FHandle) then
    FHandle := lua_open();
end;

procedure TLuaCore.DestroyHandle;
begin
  if Assigned(FHandle) and FOwnHandle then
  begin
    lua_close(FHandle);
    FHandle := nil;
    SetLength(FOwnedObjects, 0);
  end;
end;

function TLuaCore.GetHandle: TLuaState;
begin
  HandleNeeded;
  Result := FHandle;
end;

procedure TLuaCore.SetHandle(const Value: TLuaState);
begin
  FHandle := Value;
end;

procedure TLuaCore.RegisterExtension(AnExtension: ILuaExtension);
begin
  if Assigned(AnExtension) then
  begin
    AnExtension.Register(Handle);
    if AnExtension.ShouldBeSaved then
    begin
      SetLength(FOwnedObjects, Length(FOwnedObjects) + 1);
      FOwnedObjects[High(FOwnedObjects)] := AnExtension;
    end;
  end;
end;

procedure TLuaCore.RunCode(const ACode: string);
begin
  LuaCheck(luaL_dostring(Handle, PAnsiChar(UTF8String(ACode))), Handle);
end;

procedure TLuaCore.RunFile(const AFileName: string);
begin
  LuaCheck(luaL_dofile(Handle, PAnsiChar(AnsiString(AFileName))), Handle);
end;

initialization
  if not LuaLibLoaded then
    LoadLuaLib;
finalization
  FreeLuaLib;
end.
