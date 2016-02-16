unit Lua.Stack;

interface

uses
  LuaLib, Lua.Types;

type
  TLuaStack = class(TObject)
  protected
    FHandle: TLuaState;
  public
    constructor Create(const AHandle: TLuaState); virtual;

    // TODO: Should be implemented
  end;

implementation

{ TLuaStack }

constructor TLuaStack.Create(const AHandle: TLuaState);
begin
  Assert(Assigned(AHandle));
  FHandle := AHandle;
end;

end.
