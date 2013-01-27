{$A-,B-,D-,E-,F+,G+,I-,L-,N-,O+,P+,Q-,R-,S-,T-,V-,X+}
{$M 16384,0,65536}
unit rg_obj;
{
Date:   4-30-96

Descr:  RgObject is the basic object type for Renegade, for default
routines and descendibility

Code: 87
Data: 8

}
INTERFACE
uses
  Objects;

TYPE
  Rgobj=object
    IsValid:boolean;            { TRUE if currently valid, i.e. no error occured }
    Constructor Init;
    Destructor  Done;
    function ok:Boolean;        { Returns value of IsValid }
    Procedure SetOk(B:Boolean); { Sets IsValid }
  end;

IMPLEMENTATION

Constructor RgObj.Init;
begin
  IsValid := TRUE;
End;

Destructor  RgObj.Done;
begin
End;

Function  RgObj.Ok:Boolean;
begin
  Ok := IsValid;
End;

Procedure RgObj.SetOk(B:Boolean);
Begin
  IsValid := IsValid AND B;
End;

end. { of unit }
