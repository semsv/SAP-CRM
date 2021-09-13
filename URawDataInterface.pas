unit URawDataInterface;

interface

uses classes, sysutils;

 type
   TRawDataInterface = class;
   TArrayOfByte      = Array of byte;

   TRawDataInterface = class
   private
   { Private declarations }
     READ_INDEX : INTEGER;
     buff       : TArrayOfByte;
     packet     : TArrayOfByte;
   public
   { Public declarations }
     procedure LoadFromStream(Stream : TStream; Var Buffer : TArrayOfByte);
     procedure ReadData(Count : Integer; Var Buffer : TArrayOfByte);
     constructor create;
     destructor destroy;
   end;
implementation

destructor TRawDataInterface.destroy;
begin
{}
  setlength(buff, 0);
  setlength(packet, 0);
  READ_INDEX := 0;
end;

constructor TRawDataInterface.create;
begin
{}
  setlength(buff,  20*1024*1024);    // 20 MB
  setlength(packet, 1*1024*1024);    // 1  MB
  READ_INDEX := 0;
end;

procedure TRawDataInterface.ReadData(Count : Integer; Var Buffer : TArrayOfByte);
  var
    arr : TArrayOfByte;
    p   : pointer;
    i   : integer;
begin
 arr := packet;
 p   := packet;
 FillChar(p^, Count + 1, 0); // ZeroMemory
 for i := 1 to count do
  begin
    arr[ i - 1 ] := buff[ READ_INDEX ];
    READ_INDEX := READ_INDEX + 1;
  end;
 Buffer := packet;
end;

procedure TRawDataInterface.LoadFromStream(Stream : TStream; Var Buffer : TArrayOfByte);
  const rsize=2048;
  type TArrayOfByte = Array of byte;
  var
    j, x      : integer;
    index     : integer;
    BuffByte  : Array [1..rsize] of byte;
begin
  index := 0;
  for J := 1 to  (Stream.Size div rsize) do
  begin
    Stream.Read(BuffByte[1], rsize);
    for x := 1 to rsize do
    begin
      buff[index] := ord(inttohex(BuffByte[x], 2)[1]);
      index := index + 1;
      buff[index] :=ord(inttohex(BuffByte[x], 2)[2]);
      index := index + 1;
    end;
  end;
  Stream.Read(BuffByte[1], Stream.Size mod rsize);
  for x := 1 to rsize do
  begin
    buff[index] := ord(inttohex(BuffByte[x], 2)[1]);
    index := index + 1;
    buff[index] := ord(inttohex(BuffByte[x], 2)[2]);
    index := index + 1;
  end;
  Buffer := buff;
end;

end.
