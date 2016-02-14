unit LuaEngine;

interface

uses
  Generics.Collections,
  LuaLib;

type
  TLuaEngine = class;

  ILuaFunctionArgument = interface(IInterface)
    function Index: Integer;

    function IsNil: Boolean;
    function IsBoolean: Boolean;
    function IsNumber: Boolean;
    function IsCFunction: Boolean;
    function IsFunction: Boolean;
    function IsUserData: Boolean;
    function IsString: Boolean;
    function IsTable: Boolean;
    function IsThread: Boolean;

    function AsBoolean: Boolean;
    function AsCFunction: TLuaCFunction;
    function AsInteger: Integer;
    function AsNumber: Double;
    function AsUserData: Pointer;
    function AsString: string;
    function AsPointer: Pointer;
    function AsThread: TLuaState;
  end;

  TLuaFunctionArgument = class(TInterfacedObject, ILuaFunctionArgument)
  protected
    FEngine: TLuaEngine;
    FIndex: Integer;
  public
    constructor Create(const AnEngine: TLuaEngine; const AnIndex: Integer);

    function Index: Integer;

    function IsNil: Boolean;
    function IsBoolean: Boolean;
    function IsNumber: Boolean;
    function IsCFunction: Boolean;
    function IsFunction: Boolean;
    function IsUserData: Boolean;
    function IsString: Boolean;
    function IsTable: Boolean;
    function IsThread: Boolean;

    function AsBoolean: Boolean;
    function AsCFunction: TLuaCFunction;
    function AsInteger: Integer;
    function AsNumber: Double;
    function AsUserData: Pointer;
    function AsString: string;
    function AsPointer: Pointer;
    function AsThread: TLuaState;
  end;

  ILuaFunctionResult = interface
    procedure Push(const LuaState: TLuaState);
  end;

  TLuaFunctionResult = class(TInterfacedObject, ILuaFunctionResult)
  protected
    FType: (lfrBoolean, lfrInteger, lfrNumber, lfrString, lfrData, lfrPointer, lfrFunction);
    FBoolean: Boolean;
    FInteger: Integer;
    FNumber: Double;
    FString: RawByteString;
    FPointer: Pointer;
    FDataSize: Integer;
  public
    constructor Create(const Value: Boolean); overload;
    constructor Create(const Value: Integer); overload;
    constructor Create(const Value: Double); overload;
    constructor Create(const Value: RawByteString); overload;
    constructor Create(const Data: Pointer; const DataSize: Integer); overload;
    constructor Create(const Value: Pointer); overload;
    constructor Create(const Value: TLuaCFunction); overload;

    procedure Push(const LuaState: TLuaState);
  end;

  TLuaFunctionContext = class(TObject)
  protected
    FName: string;
    FEngine: TLuaEngine;
    FResults: TArray<ILuaFunctionResult>;
    function GetArguments(const Index: Integer): ILuaFunctionArgument;
    function GetArgumentsCount: Integer;
    function GetResultsCount: Integer;
    function ApplyResults: Integer;
  public
    constructor Create(const AName: string; const AnEngine: TLuaEngine);

    property Name: string read FName;
    property Engine: TLuaEngine read FEngine;
    property Arguments[const Index: Integer]: ILuaFunctionArgument read GetArguments;
    property ArgumentsCount: Integer read GetArgumentsCount;
    property ResultsCount: Integer read GetResultsCount;

    procedure PushResult(const Value: Boolean); overload;
    procedure PushResult(const Value: Integer); overload;
    procedure PushResult(const Value: Double); overload;
    procedure PushResult(const Value: RawByteString); overload;
    procedure PushResult(const Data: Pointer; const DataSize: Integer); overload;
    procedure PushResult(const Value: Pointer); overload;
    procedure PushResult(const Value: TLuaCFunction); overload;
    procedure ClearResults;
  end;

  TLuaExternalFunction = reference to procedure(const State: TLuaFunctionContext);

  TLuaEngine = class(TObject)
  private
    FCallbackList: TObjectList<TObject>;
  protected
    FHandle: TLuaState;
    procedure HandleNeeded; virtual;
    procedure DestroyHandle; virtual;
    function GetHandle: TLuaState;
  public
    property Handle: TLuaState read GetHandle;

    constructor Create; virtual;
    destructor Destroy; override;

    procedure RegisterFunction(const AName: string; const AFunction: TLuaExternalFunction);

    procedure PushGlobalVar(const AName: string; const Value: Boolean); overload;
    procedure PushGlobalVar(const AName: string; const Value: Integer); overload;
    procedure PushGlobalVar(const AName: string; const Value: Double); overload;
    procedure PushGlobalVar(const AName: string; const Value: RawByteString); overload;

    procedure RunCode(const ACode: string);
    procedure RunFile(const AFileName: string);
  end;

implementation

uses
  SysUtils;

type
  TCallback = class(TObject)
    AName: string;
    AFunction: TLuaExternalFunction;
    AEngine: TLuaEngine;
  end;

  // This function is called by Lua, it extracts the object by
  // pointer to the objects method by name, which is then called.
function LuaCallBack(AState: Lua_State): Integer; cdecl;
var
  CallBack: TCallBack; // The Object stored in the Object Table
  Context: TLuaFunctionContext;
begin
  Result := 0;

  // Retrieve first Closure Value (=Object Pointer)
  CallBack := lua_topointer(AState, lua_upvalueindex(1));

  // Execute only if Object is valid
  if (Assigned(CallBack) and Assigned(CallBack.AFunction)) then
  begin
    Context := TLuaFunctionContext.Create(CallBack.AName, CallBack.AEngine);
    try
      CallBack.AFunction(Context);
      Result := Context.ApplyResults;
    finally
      FreeAndNil(Context);
    end;
  end;
end;

constructor TLuaEngine.Create();
begin
  inherited Create;
  FCallbackList := TObjectList<TObject>.Create(true);
end;

destructor TLuaEngine.Destroy;
begin
  DestroyHandle;
  FreeAndNil(FCallbackList);
  inherited;
end;

procedure TLuaEngine.DestroyHandle;
begin
  if Assigned(FHandle) then
  begin
    Lua_Close(FHandle);
    FHandle := nil;
    FCallbackList.Clear;
  end;
end;

function TLuaEngine.GetHandle: TLuaState;
begin
  HandleNeeded;
  Result := FHandle;
end;

procedure TLuaEngine.HandleNeeded;
begin
  if not Assigned(FHandle) then
  begin
    // Load Lua Lib if not already done
    if (not LuaLibLoaded) then
      LoadLuaLib;

    // Open Library
    FHandle := Lua_Open();
    luaopen_base(FHandle);
  end;
end;

procedure TLuaEngine.PushGlobalVar(const AName: string; const Value: Integer);
begin
  lua_pushinteger(FHandle, Value);
  lua_setglobal(FHandle, PAnsiChar(AnsiString(AName)));
end;

procedure TLuaEngine.PushGlobalVar(const AName: string; const Value: Boolean);
begin
  lua_pushboolean(FHandle, Value);
  lua_setglobal(FHandle, PAnsiChar(AnsiString(AName)));
end;

procedure TLuaEngine.PushGlobalVar(const AName: string;
  const Value: RawByteString);
begin
  lua_pushlstring(FHandle, PAnsiChar(Value), Length(Value));
  lua_setglobal(FHandle, PAnsiChar(AnsiString(AName)));
end;

procedure TLuaEngine.PushGlobalVar(const AName: string; const Value: Double);
begin
  lua_pushnumber(FHandle, Value);
  lua_setglobal(FHandle, PAnsiChar(AnsiString(AName)));
end;

procedure TLuaEngine.RegisterFunction(const AName: string;
  const AFunction: TLuaExternalFunction);
var
  CallBack: TCallBack; // Callback Object
begin
  CallBack := TCallback.Create;
  CallBack.AName := AName;
  CallBack.AFunction := AFunction;
  CallBack.AEngine := Self;

  // prepare Closure value (Method Name)
  lua_pushstring(Handle, PAnsiChar(AnsiString(AName)));

  // prepare Closure value (CallBack Object Pointer)
  lua_pushlightuserdata(Handle, Pointer(CallBack));

  // set new Lua function with Closure value
  lua_pushcclosure(Handle, LuaCallBack, 1);
  lua_settable(Handle, LUA_GLOBALSINDEX);
end;

procedure TLuaEngine.RunCode(const ACode: string);
begin
  luaL_dostring(Handle, PAnsiChar(AnsiString(ACode)));
end;

procedure TLuaEngine.RunFile(const AFileName: string);
begin
  luaL_dofile(Handle, PAnsiChar(AnsiString(AFileName)));
end;

{ TLuaFunctionContext }

function TLuaFunctionContext.ApplyResults: Integer;
var
  i: Integer;
begin
  Result := Length(FResults);
  for i := 0 to High(FResults) do
    FResults[i].Push(FEngine.Handle);
end;

procedure TLuaFunctionContext.ClearResults;
begin
  SetLength(FResults, 0);
end;

constructor TLuaFunctionContext.Create(const AName: string; const AnEngine: TLuaEngine);
begin
  Assert(Assigned(AnEngine));
  FName := AName;
  FEngine := AnEngine;
end;

function TLuaFunctionContext.GetArguments(const Index: Integer): ILuaFunctionArgument;
begin
  if lua_isnone(FEngine.Handle, Index + 1) then
    Exit(nil);
  Result := TLuaFunctionArgument.Create(FEngine, Index + 1);
end;

function TLuaFunctionContext.GetArgumentsCount: Integer;
begin
  Result := lua_gettop(FEngine.Handle);
end;

function TLuaFunctionContext.GetResultsCount: Integer;
begin
  Result := Length(FResults);
end;

procedure TLuaFunctionContext.PushResult(const Value: Integer);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Value);
end;

procedure TLuaFunctionContext.PushResult(const Value: Boolean);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Value);
end;

procedure TLuaFunctionContext.PushResult(const Value: Double);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Value);
end;

procedure TLuaFunctionContext.PushResult(const Value: Pointer);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Value);
end;

procedure TLuaFunctionContext.PushResult(const Value: TLuaCFunction);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Value);
end;

procedure TLuaFunctionContext.PushResult(const Value: RawByteString);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Value);
end;

procedure TLuaFunctionContext.PushResult(const Data: Pointer; const DataSize: Integer);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := TLuaFunctionResult.Create(Data, DataSize);
end;

{ TLuaFunctionArgument }

constructor TLuaFunctionArgument.Create(const AnEngine: TLuaEngine; const AnIndex: Integer);
begin
  FEngine := AnEngine;
  FIndex := AnIndex;
end;

function TLuaFunctionArgument.AsBoolean: Boolean;
begin
  Result := lua_toboolean(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.AsCFunction: TLuaCFunction;
begin
  Result := lua_tocfunction(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.AsInteger: Integer;
begin
  Result := lua_tointeger(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.AsNumber: Double;
begin
  Result := lua_tonumber(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.AsPointer: Pointer;
begin
  Result := lua_topointer(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.AsString: string;
var
  p: PAnsiChar;
  sz: Cardinal;
  q: RawByteString;
begin
  Result := '';
  p := lua_tolstring(FEngine.Handle, FIndex, sz);
  if Assigned(p) and (sz > 0) then
  begin
    SetLength(q, sz);
    Move(p^, q[1], sz);
    Result := string(q);
  end;
end;

function TLuaFunctionArgument.AsThread: TLuaState;
begin
  Result := lua_tothread(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.AsUserData: Pointer;
begin
  Result := lua_touserdata(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.Index: Integer;
begin
  Result := FIndex - 1;
end;

function TLuaFunctionArgument.IsBoolean: Boolean;
begin
  Result := lua_isboolean(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsCFunction: Boolean;
begin
  Result := lua_iscfunction(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsFunction: Boolean;
begin
  Result := lua_isfunction(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsNil: Boolean;
begin
  Result := lua_isnil(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsNumber: Boolean;
begin
  Result := lua_isnumber(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsString: Boolean;
begin
  Result := lua_isstring(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsTable: Boolean;
begin
  Result := lua_istable(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsThread: Boolean;
begin
  Result := lua_isthread(FEngine.Handle, FIndex);
end;

function TLuaFunctionArgument.IsUserData: Boolean;
begin
  Result := lua_isuserdata(FEngine.Handle, FIndex);
end;

{ TLuaFunctionResult }

constructor TLuaFunctionResult.Create(const Value: Double);
begin
  FType := lfrNumber;
  FNumber := Value;
end;

constructor TLuaFunctionResult.Create(const Value: Integer);
begin
  FType := lfrInteger;
  FInteger := Value;
end;

constructor TLuaFunctionResult.Create(const Value: Boolean);
begin
  FType := lfrBoolean;
  FBoolean := Value;
end;

constructor TLuaFunctionResult.Create(const Value: RawByteString);
begin
  FType := lfrString;
  FString := Value;
end;

constructor TLuaFunctionResult.Create(const Value: TLuaCFunction);
begin
  FType := lfrFunction;
  FPointer := @Value;
end;

constructor TLuaFunctionResult.Create(const Value: Pointer);
begin
  FType := lfrPointer;
  FPointer := Value;
end;

constructor TLuaFunctionResult.Create(const Data: Pointer; const DataSize: Integer);
begin
  FType := lfrData;
  FPointer := Data;
  FDataSize := DataSize;
end;

procedure TLuaFunctionResult.Push(const LuaState: TLuaState);
begin
  if not Assigned(LuaState) then
    Exit;

  case FType of
    lfrBoolean: lua_pushboolean(LuaState, FBoolean);
    lfrInteger: lua_pushinteger(LuaState, FInteger);
    lfrNumber: lua_pushnumber(LuaState, FNumber);
    lfrString: lua_pushlstring(LuaState, PAnsiChar(FString), Length(FString));
    lfrData: begin
      if Assigned(FPointer) and (FDataSize > 0)
        then lua_pushlstring(LuaState, PAnsiChar(FPointer), FDataSize)
        else lua_pushnil(LuaState);
    end;
    lfrPointer: begin
      if Assigned(FPointer)
        then lua_pushlightuserdata(LuaState, FPointer)
        else lua_pushnil(LuaState);
    end;
    lfrFunction: begin
      if Assigned(FPointer)
        then lua_pushcfunction(LuaState, TLuaCFunction(FPointer))
        else lua_pushnil(LuaState);
    end;
  end;
end;

end.
