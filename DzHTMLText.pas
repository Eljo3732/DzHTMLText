{------------------------------------------------------------------------------
TDzHTMLText component
Developed by Rodrigo Depin� Dalpiaz (dig�o dalpiaz)
Label with formatting tags support

https://github.com/digao-dalpiaz/DzHTMLText

Please, read the documentation at GitHub link.

Supported Tags:
<A[:abc]></A> - Link
<B></B> - Bold
<I></I> - Italic
<U></U> - Underline
<S></S> - Strike out
<FN:abc></FN> - Font Name
<FS:123></FS> - Font Size
<FC:clColor|$999999></FC> - Font Color
<BC:clColor|$999999></BC> - Background Color
<BR> - Line Break
<L></L> - Align Left
<C></C> - Align Center
<R></R> - Align Right
<T:123> - Tab
<TF:123> - Tab with aligned break
<IMG:nnn> - Image from ImageList where 'nnn' is image index
<IMGRES:name> - PNG image from Resource where 'name' is the resource name
------------------------------------------------------------------------------}

unit DzHTMLText;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
{$IFDEF FPC}
  Controls, Classes, Messages, Graphics, Types, FGL, LCLIntf, ImgList
{$ELSE}
  Vcl.Controls, System.Classes, Winapi.Messages,
  Vcl.ImgList, Vcl.Imaging.pngimage,
  System.Generics.Collections, Vcl.Graphics, System.Types
{$ENDIF};

type
  {$IFDEF FPC}
  TObjectList<T> = class(TFPGObjectList<T>);
  TList<T> = class(TFPGList<T>);
  {$ENDIF}

  TDzHTMLText = class;

  TDHVisualItem = class //represents each visual item printed to then canvas
  private
    Rect: TRect;
    Group: Integer; //group number
    {The group is isolated at each line or tabulation to delimit text align area}
    Align: TAlignment;
    BColor: TColor; //background color
    Link: Boolean; //is a link
    LinkID: Integer; //link number
    {The link number is created sequentially, when reading text links
    and works to know the link target, stored on a TStringList, because if
    the link was saved here at a work, it will be repeat if has multiple words
    per link, spending a lot of unnecessary memory.}
    Line: Integer; //line number
    Hover: Boolean; //the mouse is over the link
  end;

  TDHVisualItem_Word = class(TDHVisualItem)
  private
    Text: String;
    Font: TFont;
    Space: Boolean; //is an space
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TDHVisualItem_Image = class(TDHVisualItem)
  private
    ImageIndex: Integer;
  end;

  TDHVisualItem_ImageResource = class(TDHVisualItem)
  private
    Picture: TPicture;
    procedure Load(Lb: TDzHTMLText; const ResourceName: String);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TDHVisualItemList = class(TObjectList<TDHVisualItem>);

  TDHKindStyleLinkProp = (tslpNormal, tslpHover); //kind of link style

  {DHStyleLinkProp is a sub-property used at Object Inspector that contains
   link formatting when selected and not selected}
  TDHStyleLinkProp = class(TPersistent)
  private
    Lb: TDzHTMLText; //owner
    Kind: TDHKindStyleLinkProp;

    FFontColor: TColor;
    FBackColor: TColor;
    FUnderline: Boolean;
    procedure SetFontColor(const Value: TColor);
    procedure SetBackColor(const Value: TColor);
    procedure SetUnderline(const Value: Boolean);
    function GetDefaultFontColor: TColor;
    function GetStoredFontColor: Boolean;
    procedure SetPropsToCanvas(C: TCanvas); //method to use at paint event
    function GetStored: Boolean; //GetStored general to use at owner
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(xLb: TDzHTMLText; xKind: TDHKindStyleLinkProp);
    procedure Assign(Source: TPersistent); override;
  published
    property FontColor: TColor read FFontColor write SetFontColor stored GetStoredFontColor;
    property BackColor: TColor read FBackColor write SetBackColor default clNone;
    property Underline: Boolean read FUnderline write SetUnderline default False;
  end;

  TDHLinkData = class
  private
    FTarget: String;
    FText: String;
  public
    property Target: String read FTarget;
    property Text: String read FText;
  end;
  TDHLinkDataList = class(TObjectList<TDHLinkData>);

  TDHEvLink = procedure(Sender: TObject; LinkID: Integer; LinkData: TDHLinkData) of object;
  TDHEvLinkClick = procedure(Sender: TObject; LinkID: Integer; LinkData: TDHLinkData; var Handled: Boolean) of object;

  TDHLineVertAlign = (vaTop, vaCenter, vaBottom);

  TDHEvRetrieveImgRes = procedure(Sender: TObject; const ResourceName: String; Picture: TPicture; var Handled: Boolean) of object;

  TDHModifiedFlag = (mfBuild, mfPaint);
  TDHModifiedFlags = set of TDHModifiedFlag;

  TDzHTMLText = class(TGraphicControl)
  private
    FAbout: String;

    LVisualItem: TDHVisualItemList; //visual item list to paint event
    LLinkData: TDHLinkDataList; //list of links info

    FText: String;
    FAutoWidth: Boolean;
    FAutoHeight: Boolean;
    FMaxWidth: Integer; //max width when using AutoWidth
    //FTransparent: Boolean; //not used because of flickering
    FAutoOpenLink: Boolean; //link auto-open with ShellExecute

    FLines: Integer; //read-only
    FTextWidth: Integer; //read-only
    FTextHeight: Integer; //read-only

    FStyleLinkNormal, FStyleLinkHover: TDHStyleLinkProp;

    FImages: TCustomImageList;

    FOnRetrieveImgRes: TDHEvRetrieveImgRes;

    FLineVertAlign: TDHLineVertAlign;

    FOnLinkEnter, FOnLinkLeave: TDHEvLink;
    FOnLinkClick, FOnLinkRightClick: TDHEvLinkClick;

    FIsLinkHover: Boolean; //if has a selected link
    FSelectedLinkID: Integer; //selected link ID

    NoCursorChange: Boolean; //lock CursorChange event
    DefaultCursor: TCursor; //default cursor when not over a link

    UpdatingSemaphore: Integer;
    InternalResizing: Boolean;

    procedure SetText(const Value: String);
    procedure SetAutoHeight(const Value: Boolean);
    procedure SetAutoWidth(const Value: Boolean);
    procedure SetMaxWidth(const Value: Integer);

    function GetStoredStyleLink(const Index: Integer): Boolean;
    procedure SetStyleLink(const Index: Integer; const Value: TDHStyleLinkProp);

    procedure DoPaint;
    procedure BuildAndPaint; //rebuild and repaint
    procedure Modified(Flags: TDHModifiedFlags);

    procedure CheckMouse(X, Y: Integer); //check links by mouse position
    procedure SetCursorWithoutChange(C: TCursor);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetLineVertAlign(const Value: TDHLineVertAlign);
    //procedure SetTransparent(const Value: Boolean);
  protected
    procedure Loaded; override;
    procedure Paint; override;
    procedure Click; override;
    procedure Resize; override;

    procedure CMColorchanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMFontchanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure CMMouseleave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer;
      Y: Integer); override;
    procedure CMCursorchanged(var Message: TMessage); message CM_CURSORCHANGED;

    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property IsLinkHover: Boolean read FIsLinkHover;
    property SelectedLinkID: Integer read FSelectedLinkID;
    function GetLinkData(LinkID: Integer): TDHLinkData; //get data by link id
    function GetSelectedLinkData: TDHLinkData; //get data of selected link

    procedure Rebuild; //rebuild words

    procedure BeginUpdate;
    procedure EndUpdate(ForceRepaint: Boolean = True);
  published
    property Align;
    property Anchors;
    property Color;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;

    {$IFDEF DCC}
    property OnGesture;
    property OnMouseActivate;
    {$ENDIF}
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;

    property Text: String read FText write SetText;
    //property Transparent: Boolean read FTransparent write SetTransparent default False;

    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default False;
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default False;
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth default 0;

    property StyleLinkNormal: TDHStyleLinkProp index 1 read FStyleLinkNormal write SetStyleLink stored GetStoredStyleLink;
    property StyleLinkHover: TDHStyleLinkProp index 2 read FStyleLinkHover write SetStyleLink stored GetStoredStyleLink;

    property Images: TCustomImageList read FImages write SetImages;

    property Lines: Integer read FLines;
    property TextWidth: Integer read FTextWidth;
    property TextHeight: Integer read FTextHeight;

    property OnLinkEnter: TDHEvLink read FOnLinkEnter write FOnLinkEnter;
    property OnLinkLeave: TDHEvLink read FOnLinkLeave write FOnLinkLeave;
    property OnLinkClick: TDHEvLinkClick read FOnLinkClick write FOnLinkClick;
    property OnLinkRightClick: TDHEvLinkClick read FOnLinkRightClick write FOnLinkRightClick;

    property OnRetrieveImgRes: TDHEvRetrieveImgRes read FOnRetrieveImgRes write FOnRetrieveImgRes;

    property AutoOpenLink: Boolean read FAutoOpenLink write FAutoOpenLink default True;

    property LineVertAlign: TDHLineVertAlign read FLineVertAlign write SetLineVertAlign default vaTop;

    property About: String read FAbout;
  end;

procedure Register;

implementation

uses
{$IFDEF FPC}
  {$IFDEF MSWINDOWS}Windows, {$ENDIF}SysUtils, LResources
{$ELSE}
  System.SysUtils, System.UITypes, Winapi.Windows, Winapi.ShellAPI
{$ENDIF};

procedure Register;
begin
  {$IFDEF FPC}{$I DzHTMLText.lrs}{$ENDIF}
  RegisterComponents('Digao', [TDzHTMLText]);
end;

//

constructor TDHVisualItem_Word.Create;
begin
  inherited;
  Font := TFont.Create;
end;

destructor TDHVisualItem_Word.Destroy;
begin
  Font.Free;
  inherited;
end;

constructor TDHVisualItem_ImageResource.Create;
begin
  inherited;
  Picture := TPicture.Create;
end;

destructor TDHVisualItem_ImageResource.Destroy;
begin
  Picture.Free;
  inherited;
end;

procedure TDHVisualItem_ImageResource.Load(Lb: TDzHTMLText; const ResourceName: String);
type TPNG={$IFDEF FPC}TPortableNetworkGraphic{$ELSE}TPngImage{$ENDIF};
var
  Handled: Boolean;
  PNG: TPNG;
begin
  if csDesigning in Lb.ComponentState then Exit;

  Handled := False;
  if Assigned(Lb.FOnRetrieveImgRes) then
    Lb.FOnRetrieveImgRes(Lb, ResourceName, Picture, Handled);

  if not Handled then
  begin
    PNG := TPNG.Create;
    try
      try
        PNG.LoadFromResourceName(HInstance, ResourceName);
      except
        //resource not found or invalid
      end;
      Picture.Assign(PNG);
    finally
      PNG.Free;
    end;
  end;
end;

//

constructor TDzHTMLText.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  //Warning! The use of transparency in the component causes flickering

  FAbout := 'Digao Dalpiaz / Version 1.2';

  FStyleLinkNormal := TDHStyleLinkProp.Create(Self, tslpNormal);
  FStyleLinkHover := TDHStyleLinkProp.Create(Self, tslpHover);
  LVisualItem := TDHVisualItemList.Create;
  LLinkData := TDHLinkDataList.Create;

  FAutoOpenLink := True;

  FSelectedLinkID := -1;

  DefaultCursor := Cursor;

  {$IFDEF FPC}
  //Lazarus object starts too small
  Width := 200;
  Height := 100;
  {$ENDIF}
end;

destructor TDzHTMLText.Destroy;
begin
  FStyleLinkNormal.Free;
  FStyleLinkHover.Free;
  LVisualItem.Free;
  LLinkData.Free;
  inherited;
end;

procedure TDzHTMLText.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FImages then
      FImages := nil;
  end;
end;

procedure TDzHTMLText.SetImages(const Value: TCustomImageList);
begin
  if Value <> FImages then
  begin
    FImages := Value;
    if FImages <> nil then
      FImages.FreeNotification(Self);

    BuildAndPaint;
  end;
end;

procedure TDzHTMLText.Loaded;
begin
  {Warning! When a component is inserted at design-time, the Loaded
  is not fired, because there is nothing to load. The Loaded is only fired
  when loading component that already has saved properties on DFM file.}
  inherited;
  Rebuild;
end;

procedure TDzHTMLText.Modified(Flags: TDHModifiedFlags);
begin
  if UpdatingSemaphore>0 then Exit;

  if mfBuild in Flags then Rebuild;
  if mfPaint in Flags then Invalidate;
end;

procedure TDzHTMLText.BuildAndPaint;
begin
  //Rebuild words and repaint
  Modified([mfBuild, mfPaint]);
end;

procedure TDzHTMLText.SetAutoHeight(const Value: Boolean);
begin
  if Value<>FAutoHeight then
  begin
    FAutoHeight := Value;

    if Value then Modified([mfBuild]);
  end;
end;

procedure TDzHTMLText.SetAutoWidth(const Value: Boolean);
begin
  if Value<>FAutoWidth then
  begin
    FAutoWidth := Value;

    if Value then Modified([mfBuild]);
  end;
end;

procedure TDzHTMLText.SetMaxWidth(const Value: Integer);
begin
  if Value<>FMaxWidth then
  begin
    FMaxWidth := Value;

    Modified([mfBuild]);
  end;
end;

procedure TDzHTMLText.SetText(const Value: String);
begin
  if Value<>FText then
  begin
    FText := Value;

    BuildAndPaint;
  end;
end;

procedure TDzHTMLText.SetLineVertAlign(const Value: TDHLineVertAlign);
begin
  if Value<>FLineVertAlign then
  begin
    FLineVertAlign := Value;

    BuildAndPaint;
  end;
end;

procedure TDzHTMLText.BeginUpdate;
begin
  Inc(UpdatingSemaphore);
end;

procedure TDzHTMLText.EndUpdate(ForceRepaint: Boolean = True);
begin
  if UpdatingSemaphore=0 then
    raise Exception.Create('There is no update started');

  Dec(UpdatingSemaphore);
  if ForceRepaint and (UpdatingSemaphore=0) then
    BuildAndPaint;
end;

{procedure TDzHTMLText.SetTransparent(const Value: Boolean);
begin
  if Value<>FTransparent then
  begin
    FTransparent := Value;

    Modified([mfPaint]);
  end;
end;}

procedure TDzHTMLText.CMColorchanged(var Message: TMessage);
begin
  {$IFDEF FPC}if Message.Result=0 then {};{$ENDIF} //avoid unused var warning
  Modified([mfPaint]);
end;

procedure TDzHTMLText.CMFontchanged(var Message: TMessage);
begin
  {$IFDEF FPC}if Message.Result=0 then {};{$ENDIF} //avoid unused var warning
  BuildAndPaint;
end;

procedure TDzHTMLText.Resize;
begin
  if InternalResizing then Exit;

  //on component creating, there is no parent and the resize is fired,
  //so, the canvas is not present at this moment.
  if HasParent then
    Modified([mfBuild]);

  inherited;
end;

procedure TDzHTMLText.Paint;
begin
  inherited;
  DoPaint;
end;

procedure TDzHTMLText.DoPaint;
var W: TDHVisualItem;
    B: {$IFDEF DCC}Vcl.{$ENDIF}Graphics.TBitmap;
begin
  //Using internal bitmap as a buffer to reduce flickering
  B := {$IFDEF DCC}Vcl.{$ENDIF}Graphics.TBitmap.Create;
  try
    B.SetSize(Width, Height);

    //if not FTransparent then
    //begin
      {$IFDEF FPC}
      if (Color=clDefault) and (ParentColor) then B.Canvas.Brush.Color := GetColorresolvingParent else
      {$ENDIF}
      B.Canvas.Brush.Color := Color;
      B.Canvas.FillRect(ClientRect);
    //end;

    if csDesigning in ComponentState then
    begin
      B.Canvas.Pen.Style := psDot;
      B.Canvas.Pen.Color := clBtnShadow;
      B.Canvas.Brush.Style := bsClear;
      B.Canvas.Rectangle(ClientRect);
    end;

    for W in LVisualItem do
    begin
      if W is TDHVisualItem_Word then
        B.Canvas.Font.Assign(TDHVisualItem_Word(W).Font);

      if W.BColor<>clNone then
        B.Canvas.Brush.Color := W.BColor
      else
        B.Canvas.Brush.Style := bsClear;

      if W.Link then
      begin
        if W.Hover then //selected
          FStyleLinkHover.SetPropsToCanvas(B.Canvas)
        else
          FStyleLinkNormal.SetPropsToCanvas(B.Canvas);
      end;

      if W is TDHVisualItem_Word then
        with TDHVisualItem_Word(W) do
        begin
          DrawText(B.Canvas.Handle,
           {$IFDEF FPC}PChar({$ENDIF}Text{$IFDEF FPC}){$ENDIF},
           -1, W.Rect, DT_NOCLIP or DT_NOPREFIX);
          {Using DrawText, because TextOut has no clip option, which causes
          bad overload of text when painting using background, oversizing the
          text area wildly.}
        end
      else
      if W is TDHVisualItem_Image then
        with TDHVisualItem_Image(W) do
        begin
          B.Canvas.FillRect(W.Rect);
          if Assigned(FImages) then
            FImages.Draw(B.Canvas, W.Rect.Left, W.Rect.Top, ImageIndex);
        end
      else
      if W is TDHVisualItem_ImageResource then
        with TDHVisualItem_ImageResource(W) do
        begin
          B.Canvas.FillRect(W.Rect);
          B.Canvas.Draw(W.Rect.Left, W.Rect.Top, Picture.Graphic);
        end
    end;

    Canvas.Draw(0, 0, B); //to reduce flickering
  finally
    B.Free;
  end;
end;

function TDzHTMLText.GetLinkData(LinkID: Integer): TDHLinkData;
begin
  Result := LLinkData[LinkID];
end;

function TDzHTMLText.GetSelectedLinkData: TDHLinkData;
begin
  Result := LLinkData[FSelectedLinkID];
end;

procedure TDzHTMLText.CMCursorchanged(var Message: TMessage);
begin
  {$IFDEF FPC}if Message.Result=0 then {};{$ENDIF} //avoid unused var warning

  if NoCursorChange then Exit;

  DefaultCursor := Cursor; //save default cursor to when link not selected
end;

procedure TDzHTMLText.SetCursorWithoutChange(C: TCursor);
begin
  //Set cursor, but without fire cursor change event
  NoCursorChange := True;
  try
    Cursor := C;
  finally
    NoCursorChange := False;
  end;
end;

procedure TDzHTMLText.CheckMouse(X, Y: Integer);
var FoundHover, HasChange, Old: Boolean;
    LinkID: Integer;
    W: TDHVisualItem;
begin
  FoundHover := False;
  HasChange := False;
  LinkID := -1;

  //find the first word, if there is any
  for W in LVisualItem do
    if W.Link then
    begin
      if W.Rect.Contains({$IFDEF FPC}Types.{$ENDIF}Point(X, Y)) then //selected
      begin
        FoundHover := True; //found word of a link selected
        LinkID := W.LinkID;

        Break;
      end;
    end;

  //set as selected all the words of same link, and unselect another links
  for W in LVisualItem do
    if W.Link then
    begin
      Old := W.Hover;
      W.Hover := (W.LinkID = LinkID);
      if Old<>W.Hover then HasChange := True; //changed
    end;

  if HasChange then //there is any change
  begin
    if FoundHover then //enter the link
    begin
      SetCursorWithoutChange(crHandPoint); //set HandPoint cursor
      FIsLinkHover := True;
      FSelectedLinkID := LinkID;
      if Assigned(FOnLinkEnter) then
        FOnLinkEnter(Self, LinkID, LLinkData[LinkID]);
    end else
    begin //leave the link
      SetCursorWithoutChange(DefaultCursor); //back to default cursor
      FIsLinkHover := False;
      LinkID := FSelectedLinkID; //save to use on OnLinkLeave event
      FSelectedLinkID := -1;
      if Assigned(FOnLinkLeave) then
        FOnLinkLeave(Self, LinkID, LLinkData[LinkID]);
    end;

    Invalidate;
  end;
end;

procedure TDzHTMLText.Click;
var Handled: Boolean;
  aTarget: String;
begin
  if FIsLinkHover then
  begin
    Handled := False;
    if Assigned(FOnLinkClick) then
      FOnLinkClick(Self, FSelectedLinkID, LLinkData[FSelectedLinkID], Handled);

    if FAutoOpenLink and not Handled then
    begin
      aTarget := LLinkData[FSelectedLinkID].FTarget;
      {$IFDEF MSWINDOWS}
      ShellExecute(0, '', PChar(aTarget), '', '', 0);
      {$ELSE}
      if aTarget.StartsWith('http://', True)
        or aTarget.StartsWith('https://', True)
        or aTarget.StartsWith('www.', True)
      then
        OpenURL(aTarget)
      else
        OpenDocument(aTarget);
      {$ENDIF}
    end;
  end;

  inherited;
end;

procedure TDzHTMLText.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var Handled: Boolean;
begin
  if Button = mbRight then
    if IsLinkHover then
      if Assigned(FOnLinkRightClick) then
      begin
        Handled := False;
        FOnLinkRightClick(Self, FSelectedLinkID, LLinkData[FSelectedLinkID], Handled);
      end;

  inherited;
end;

procedure TDzHTMLText.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  CheckMouse(X, Y);

  inherited;
end;

procedure TDzHTMLText.CMMouseleave(var Message: TMessage);
begin
  //Mouse leaves the component
  CheckMouse(-1, -1);

  inherited;
end;

//

type
  TTokenKind = (
    ttInvalid,
    ttBold, ttItalic, ttUnderline, ttStrike,
    ttFontName, ttFontSize, ttFontColor, ttBackColor,
    ttTab, ttTabF, ttSpace,
    ttBreak, ttText, ttLink,
    ttAlignLeft, ttAlignCenter, ttAlignRight,
    ttImage, ttImageResource);

  TToken = class
    Kind: TTokenKind;
    TagClose: Boolean;
    Text: String;
    Value: Integer;
  end;

  TListToken = class(TObjectList<TToken>)
    function GetLinkText(IEnd: Integer): String;
  end;

  TBuilder = class
  private
    Lb: TDzHTMLText;
    L: TListToken;
    LGroupBound: TList<Integer>; //bounds list of the group
    {The list of created with the X position of limit where the group ends
     to use on text align until the group limit}

    LinesHeight: TList<Integer>;

    CalcWidth, CalcHeight: Integer; //width and height to set at component when using auto

    function ProcessTag(const Tag: String): Boolean;
    procedure AddToken(aKind: TTokenKind; aTagClose: Boolean = False; aText: String = ''; aValue: Integer = 0);

    procedure BuildTokens; //create list of tokens
    procedure BuildWords; //create list of words
    procedure CheckAligns; //realign words
  public
    constructor Create;
    destructor Destroy; override;
  end;

constructor TBuilder.Create;
begin
  inherited;
  L := TListToken.Create;
  LGroupBound := TList<Integer>.Create;
  LinesHeight := TList<Integer>.Create;
end;

destructor TBuilder.Destroy;
begin
  L.Free;
  LGroupBound.Free;
  LinesHeight.Free;
  inherited;
end;

procedure TDzHTMLText.Rebuild;
var B: TBuilder;
begin
  if csLoading in ComponentState then Exit;

  LVisualItem.Clear; //clean old words
  LLinkData.Clear; //clean old links

  B := TBuilder.Create;
  try
    B.Lb := Self;

    B.BuildTokens;
    B.BuildWords;
    B.CheckAligns;

    FTextWidth := B.CalcWidth;
    FTextHeight := B.CalcHeight;

    InternalResizing := True;
    try
      if FAutoWidth then Width := B.CalcWidth;
      if FAutoHeight then Height := B.CalcHeight;
    finally
      InternalResizing := False;
    end

  finally
    B.Free;
  end;
end;

//

function ReplaceForcedChars(A: String): String;
begin
  //Allow tag characters at text

  A := StringReplace(A, '&lt;', '<', [rfReplaceAll]);
  A := StringReplace(A, '&gt;', '>', [rfReplaceAll]);

  Result := A;
end;

function ParamToColor(A: String): TColor;
begin
  if A.StartsWith('$') then Insert('00', A, 2);
  {At HTML, is used Hexadecimal color code with 6 digits, the same used at
  this component. However the Delphi works with 8 digits, but the first two
  digits are always "00"}

  try
    Result := StringToColor(A);
  except
    Result := clNone;
  end;
end;

procedure TBuilder.AddToken(aKind: TTokenKind; aTagClose: Boolean = False; aText: String = ''; aValue: Integer = 0);
var T: TToken;
begin
  T := TToken.Create;
  T.Kind := aKind;
  T.TagClose := aTagClose;
  T.Text := aText;
  T.Value := aValue;
  L.Add(T);
end;

function Tag_Index_ProcValue(const Value: String; var Valid: Boolean): Integer;
begin
  Result := StrToIntDef(Value, -1);
  Valid := (Result>-1);
end;

function Tag_Number_ProcValue(const Value: String; var Valid: Boolean): Integer;
begin
  Result := StrToIntDef(Value, 0);
  Valid := (Result>0);
end;

function Tag_Color_ProcValue(const Value: String; var Valid: Boolean): Integer;
begin
  Result := ParamToColor(Value);
  Valid := (Result<>clNone);
end;

type TDefToken = record
  Ident: String;
  Kind: TTokenKind;
  Single: Boolean; //without close tag
  AllowPar, OptionalPar: Boolean;
  ProcValue: function(const Value: String; var Valid: Boolean): Integer;
end;
const DEF_TOKENS: array[0..16] of TDefToken = (
  (Ident: 'BR'; Kind: ttBreak; Single: True),
  (Ident: 'B'; Kind: ttBold),
  (Ident: 'I'; Kind: ttItalic),
  (Ident: 'U'; Kind: ttUnderline),
  (Ident: 'S'; Kind: ttStrike),
  (Ident: 'FN'; Kind: ttFontName; AllowPar: True),
  (Ident: 'FS'; Kind: ttFontSize; AllowPar: True; ProcValue: Tag_Number_ProcValue),
  (Ident: 'FC'; Kind: ttFontColor; AllowPar: True; ProcValue: Tag_Color_ProcValue),
  (Ident: 'BC'; Kind: ttBackColor; AllowPar: True; ProcValue: Tag_Color_ProcValue),
  (Ident: 'A'; Kind: ttLink; AllowPar: True; OptionalPar: True),
  (Ident: 'L'; Kind: ttAlignLeft),
  (Ident: 'C'; Kind: ttAlignCenter),
  (Ident: 'R'; Kind: ttAlignRight),
  (Ident: 'T'; Kind: ttTab; Single: True; AllowPar: True; ProcValue: Tag_Number_ProcValue),
  (Ident: 'TF'; Kind: ttTabF; Single: True; AllowPar: True; ProcValue: Tag_Number_ProcValue),
  (Ident: 'IMG'; Kind: ttImage; Single: True; AllowPar: True; ProcValue: Tag_Index_ProcValue),
  (Ident: 'IMGRES'; Kind: ttImageResource; Single: True; AllowPar: True)
);

function TBuilder.ProcessTag(const Tag: String): Boolean;
var TOff, TOn, HasPar, ValidPar: Boolean;
    Value: Integer;
    A, Par: String;
    I: Integer;
    Def: TDefToken;
begin
  //Result=True means valid tag
  Result := False;
  A := Tag;

  TOff := False;
  if A.StartsWith('/') then //closing tag
  begin
    TOff := True;
    Delete(A, 1, 1);
  end;
  TOn := not TOff;

  HasPar := False;
  Par := '';
  I := Pos(':', A); //find parameter
  if I>0 then //has parameter
  begin
    HasPar := True;
    Par := A.Substring(I); //zero-based
    A := Copy(A, 1, I-1);
  end;

  if HasPar then
  begin
    if Par='' then Exit; //blank parameter specified
    if TOff then Exit; //tag closing with parameter
  end;

  A := UpperCase(A);

  for Def in DEF_TOKENS do
  begin
    if Def.Ident=A then
    begin
      if TOn then
      begin
        if (not Def.AllowPar) and (HasPar) then Exit; //parameter not allowed
        if (Def.AllowPar) and (not Def.OptionalPar) and (not HasPar) then Exit; //parameter required
      end else
      begin
        if Def.Single then Exit; //close-tag on single tag        
      end;

      Value := 0;
      if TOn and HasPar and Assigned(Def.ProcValue) then
      begin
        ValidPar := True;
        Value := Def.ProcValue(Par, ValidPar);
        if not ValidPar then Exit;
      end;

      AddToken(Def.Kind, TOff, Par, Value);
      Result := True;
      Exit;
    end;
  end;
end;

type
  TCharUtils = class
    class function FindNextWordBreakChar(const A: String): Integer; inline;
    class function IsCJKChar(const C: Char): Boolean; inline;
  end;

class function TCharUtils.FindNextWordBreakChar(const A: String): Integer;
var I: Integer;
  C: Char;
begin
  Result := 0;

  for I := 1 to A.Length do
  begin
    C := A[I];
    if CharInSet(C, [' ','<','>','/','\']) or IsCJKChar(C) then
    begin // !!! should never find space or tags at first char
      Result := I;
      Break;
    end;
  end;
end;

class function TCharUtils.IsCJKChar(const C: Char): Boolean; //return if char is Chinese-Japanese-Korean
begin
//East Asian languages break lines in all chars, so each char must be considered as a full word.
{
Block                                   Range       Comment
CJK Unified Ideographs                  4E00-9FFF   Common
CJK Unified Ideographs Extension A      3400-4DBF   Rare
CJK Unified Ideographs Extension B      20000-2A6DF Rare, historic
CJK Unified Ideographs Extension C      2A700�2B73F Rare, historic
CJK Unified Ideographs Extension D      2B740�2B81F Uncommon, some in current use
CJK Unified Ideographs Extension E      2B820�2CEAF Rare, historic
CJK Compatibility Ideographs            F900-FAFF   Duplicates, unifiable variants, corporate characters
CJK Compatibility Ideographs Supplement 2F800-2FA1F Unifiable variants
}
  Result := False;
  if C < #10000 then Exit; //fast check

  case Integer(C) of
    $4E00..$9FFF,
    $3400..$4DBF,
    $20000..$2A6DF,
    $2A700..$2B73F,
    $2B740..$2B81F,
    $2B820..$2CEAF,
    $F900..$FAFF,
    $2F800..$2FA1F: Result := True;
  end;
end;

procedure TBuilder.BuildTokens;
var Text, A: String;
    CharIni: Char;
    I, Jump: Integer;
begin
  Text := StringReplace(Lb.FText, #13#10, '<BR>', [rfReplaceAll]);
  while Text<>'' do
  begin
    A := Text;
    CharIni := A[1];

    if CharIni = '<' then //starts with tag opening
    begin
      Delete(A, 1, 1);
      I := Pos('>', A); //find tag closing
      if I>0 then
      begin
        A := Copy(A, 1, I-1);
        if not ProcessTag(A) then AddToken(ttInvalid);
        Jump := 1+Length(A)+1;
      end else
      begin
        //losted tag opening
        AddToken(ttInvalid);
        Jump := 1;
      end;
    end else
    if CharIni = '>' then
    begin
      //losted tag closing
      AddToken(ttInvalid);
      Jump := 1;
    end else
    if CharIni = ' ' then //space
    begin
      AddToken(ttSpace, False, ' ');
      Jump := 1;
    end else
    begin //all the rest is text
      I := TCharUtils.FindNextWordBreakChar(A);
      //when word break at first char, let add the char itself alone.
      //when word break at other next chars, consider until char before word-break char.
      if I>1 then Dec(I) else
        if I=0 then I := Length(A);

      A := Copy(A, 1, I);
      AddToken(ttText, False, ReplaceForcedChars(A));
      Jump := I;
    end;

    Delete(Text, 1, Jump);
  end;
end;

type
  TListStack<T> = class(TList<T>)
    procedure AddOrDel(Token: TToken; const XValue: T);
  end;

procedure TListStack<T>.AddOrDel(Token: TToken; const XValue: T);
begin
  if Token.TagClose then
  begin
    if Count>1 then
      Delete(Count-1);
  end else
    Add(XValue);
end;

procedure TBuilder.BuildWords;
var C: TCanvas;

    X, Y, HighW, HighH, LineCount: Integer;
    LastTabF: Boolean; //last tabulation was TabF (with break align)
    LastTabF_X: Integer;

  procedure DoLineBreak;
  begin
    if HighH=0 then HighH := C.TextHeight(' '); //line without content
    Inc(Y, HighH); //inc biggest height of the line
    LinesHeight.Add(HighH); //include total line height in list
    HighH := 0; //clear line height

    if X>HighW then HighW := X; //store width of biggest line
    X := 0; //carriage return :)
    if LastTabF then X := LastTabF_X; //last line breaks with TabF

    LGroupBound.Add(-1); //add line bound to use in group align (-1 means full width)
    Inc(LineCount);
  end;

var
  T: TToken;
  I: Integer;

  Ex: TSize; FS: TFontStyles; PreWidth: Integer;

  LinkOn: Boolean;
  LinkID: Integer;

  BackColor: TColor;
  Align: TAlignment;

  LBold: TListStack<Boolean>;
  LItalic: TListStack<Boolean>;
  LUnderline: TListStack<Boolean>;
  LStrike: TListStack<Boolean>;
  LFontName: TListStack<String>;
  LFontSize: TListStack<Integer>;
  LFontColor: TListStack<TColor>;
  LBackColor: TListStack<TColor>;
  LAlign: TListStack<TAlignment>;

  W: TDHVisualItem;

  LinkData: TDHLinkData;

  vBool: Boolean; //Required for Lazarus
begin
  C := Lb.Canvas;
  C.Font.Assign(Lb.Font);

  BackColor := clNone;
  Align := taLeftJustify;

  LBold := TListStack<Boolean>.Create;
  LItalic := TListStack<Boolean>.Create;
  LUnderline := TListStack<Boolean>.Create;
  LStrike := TListStack<Boolean>.Create;
  LFontName := TListStack<String>.Create;
  LFontSize := TListStack<Integer>.Create;
  LFontColor := TListStack<TColor>.Create;
  LBackColor := TListStack<TColor>.Create;
  LAlign := TListStack<TAlignment>.Create;
  try
    vBool := fsBold in C.Font.Style; LBold.Add(vBool);
    vBool := fsItalic in C.Font.Style; LItalic.Add(vBool);
    vBool := fsUnderline in C.Font.Style; LUnderline.Add(vBool);
    vBool := fsStrikeOut in C.Font.Style; LStrike.Add(vBool);
    LFontName.Add(C.Font.Name);
    LFontSize.Add(C.Font.Size);
    LFontColor.Add(C.Font.Color);
    LBackColor.Add(BackColor);
    LAlign.Add(Align);

    X := 0;
    Y := 0;

    HighW := 0;
    HighH := 0;

    LineCount := 0;

    LastTabF := False;
    LastTabF_X := 0;

    LinkOn := False;
    LinkID := -1;

    for I := 0 to L.Count-1 do
    begin
      T := L[I];

      case T.Kind of
        ttBold, ttItalic, ttUnderline, ttStrike:
          begin
            case T.Kind of
              ttBold: LBold.AddOrDel(T, True);
              ttItalic: LItalic.AddOrDel(T, True);
              ttUnderline: LUnderline.AddOrDel(T, True);
              ttStrike: LStrike.AddOrDel(T, True);
            end;

            FS := [];
            if LBold.Last then Include(FS, fsBold);
            if LItalic.Last then Include(FS, fsItalic);
            if LUnderline.Last then Include(FS, fsUnderline);
            if LStrike.Last then Include(FS, fsStrikeOut);
            C.Font.Style := FS;
          end;
        ttFontName:
          begin
            LFontName.AddOrDel(T, T.Text);
            C.Font.Name := LFontName.Last;
          end;
        ttFontSize:
          begin
            LFontSize.AddOrDel(T, T.Value);
            C.Font.Size := LFontSize.Last;
          end;
        ttFontColor:
          begin
            LFontColor.AddOrDel(T, T.Value);
            C.Font.Color := LFontColor.Last;
          end;
        ttBackColor:
          begin
            LBackColor.AddOrDel(T, T.Value);
            BackColor := LBackColor.Last;
          end;

        ttAlignLeft, ttAlignCenter, ttAlignRight:
          begin
            case T.Kind of
              ttAlignLeft: Align := taLeftJustify;
              ttAlignCenter: Align := taCenter;
              ttAlignRight: Align := taRightJustify;
            end;
            LAlign.AddOrDel(T, Align);
            Align := LAlign.Last;
          end;

        ttText, ttSpace, ttInvalid, ttImage, ttImageResource:
        begin
          case T.Kind of
            ttSpace: T.Text := ' ';
            ttInvalid: T.Text := '<?>';
          end;

          W := nil;
          try
            case T.Kind of
              ttImage:
              begin
                W := TDHVisualItem_Image.Create;
                with TDHVisualItem_Image(W) do
                begin
                  ImageIndex := T.Value;
                end;

                if Assigned(Lb.FImages) then
                begin
                  Ex.Width := Lb.FImages.Width;
                  Ex.Height := Lb.FImages.Height;
                end else
                begin
                  Ex.Width := 0;
                  Ex.Height := 0;
                end;
              end;

              ttImageResource:
              begin
                W := TDHVisualItem_ImageResource.Create;
                with TDHVisualItem_ImageResource(W) do
                begin
                  Load(Lb, T.Text);

                  Ex.Width := Picture.Width;
                  Ex.Height := Picture.Height;
                end;
              end;

              else
              begin
                W := TDHVisualItem_Word.Create;
                with TDHVisualItem_Word(W) do
                begin
                  Text := T.Text;
                  Font.Assign(C.Font);
                  Space := T.Kind=ttSpace;

                  Ex := C.TextExtent(Text);
                end;
              end;
            end;

            PreWidth := X+Ex.Width;
            if ((Lb.FAutoWidth) and (Lb.FMaxWidth>0) and (PreWidth>Lb.FMaxWidth))
              or ((not Lb.FAutoWidth) and (PreWidth>Lb.Width)) then
            begin
              //clear last word on line break when is space to not consume pixels at end of line
              if (Lb.LVisualItem.Count>0) and
                (Lb.LVisualItem.Last is TDHVisualItem_Word) and
                TDHVisualItem_Word(Lb.LVisualItem.Last).Space then
              begin
                Dec(X, Lb.LVisualItem.Last.Rect.Width);
                Lb.LVisualItem.Delete(Lb.LVisualItem.Count-1);
              end;

              DoLineBreak;
              if T.Kind=ttSpace then Continue;
            end;
            if Ex.Height>HighH then HighH := Ex.Height; //biggest height of the line

            //Common properties of Visual Item
            W.Rect := {$IFDEF FPC}Types.{$ENDIF}Rect(X, Y, X+Ex.Width, Y+Ex.Height);
            W.Group := LGroupBound.Count;
            W.Align := Align;
            W.BColor := BackColor;
            W.Link := LinkOn;
            W.LinkID := LinkID;
            W.Line := LineCount;

            Lb.LVisualItem.Add(W);
            W := nil;
          finally
            if W<>nil then W.Free;
          end;
          Inc(X, Ex.Width);
        end;

        ttLink:
        begin
          if T.TagClose then
          begin
            if LinkID<>-1 then
              Lb.LLinkData[LinkID].FText := L.GetLinkText(I); //set link display text on the link data object

            LinkOn := False;
            LinkID := -1;
          end else
          begin
            LinkData := TDHLinkData.Create;
            LinkData.FTarget := T.Text;

            LinkOn := True;
            LinkID := Lb.LLinkData.Add(LinkData); //add target of the link on list
          end;
        end;

        ttTab, ttTabF:
        begin
          X := T.Value; //cursor position

          LastTabF := T.Kind=ttTabF;
          LastTabF_X := X;

          LGroupBound.Add(X); //add bound on last group to use at text align
        end;

        ttBreak:
        begin
          LastTabF := False; //clear TabF
          DoLineBreak;
        end;
      end;
    end;
  finally
    LBold.Free;
    LItalic.Free;
    LUnderline.Free;
    LStrike.Free;
    LFontName.Free;
    LFontSize.Free;
    LFontColor.Free;
    LBackColor.Free;
    LAlign.Free;
  end;

  if Lb.LVisualItem.Count>0 then DoLineBreak;
  CalcWidth := HighW;
  CalcHeight := Y;
  Lb.FLines := LineCount;
end;

procedure TBuilder.CheckAligns;
var W: TDHVisualItem;
    LW: array of Integer;
    Group, I, SumW, Offset, GrpW: Integer;
begin
  SetLength(LW, LGroupBound.Count);

  Group := -1;
  SumW := 0;

  for I := 0 to Lb.LVisualItem.Count-1 do
  begin
    W := Lb.LVisualItem[I];

    if W.Group<>Group then //enter new group
    begin
      if I>0 then
        LW[Group] := SumW; //add last group width sum

      Group := W.Group;
      SumW := W.Rect.Left; //where first group starts
    end;

    Inc(SumW, W.Rect.Width);
    if I=Lb.LVisualItem.Count-1 then LW[Group] := SumW;
  end;

  for W in Lb.LVisualItem do
  begin
    //horizontal align
    if W.Align in [taCenter, taRightJustify] then
    begin
      GrpW := LGroupBound[W.Group];
      if GrpW = -1 then
      begin //group has full width
        if Lb.FAutoWidth then GrpW := CalcWidth else GrpW := Lb.Width;
      end;

      Offset := GrpW - LW[W.Group];
      if W.Align=taCenter then Offset := Offset div 2;

      W.Rect.Offset(Offset, 0);
    end;

    //vertical align
    if Lb.FLineVertAlign in [vaCenter, vaBottom] then
    begin
      Offset := LinesHeight[W.Line] - W.Rect.Height;
      if Lb.FLineVertAlign=vaCenter then Offset := Offset div 2;

      W.Rect.Offset(0, Offset);
    end;
  end;
end;

{$REGION 'StyleLinkProp'}
constructor TDHStyleLinkProp.Create(xLb: TDzHTMLText; xKind: TDHKindStyleLinkProp);
begin
  inherited Create;

  Lb := xLb;
  Kind := xKind;

  FFontColor := GetDefaultFontColor;
  FBackColor := clNone;
end;

function TDHStyleLinkProp.GetOwner: TPersistent;
begin
  Result := Lb;
end;

function TDHStyleLinkProp.GetDefaultFontColor: TColor;
begin
  Result := clNone;
  case Kind of
    tslpNormal: Result := clBlue;
    tslpHover: Result := clRed;
  end;
end;

function TDHStyleLinkProp.GetStoredFontColor: Boolean;
begin
  Result := FFontColor<>GetDefaultFontColor;
end;

procedure TDHStyleLinkProp.SetFontColor(const Value: TColor);
begin
  if Value <> FFontColor then
  begin
    FFontColor := Value;

    Lb.BuildAndPaint;
  end;
end;

procedure TDHStyleLinkProp.SetBackColor(const Value: TColor);
begin
  if Value <> FBackColor then
  begin
    FBackColor := Value;

    Lb.BuildAndPaint;
  end;
end;

procedure TDHStyleLinkProp.SetUnderline(const Value: Boolean);
begin
  if Value <> FUnderline then
  begin
    FUnderline := Value;

    Lb.BuildAndPaint;
  end;
end;

procedure TDHStyleLinkProp.SetPropsToCanvas(C: TCanvas);
begin
  if FFontColor<>clNone then C.Font.Color := FFontColor;
  if FBackColor<>clNone then C.Brush.Color := FBackColor;
  if FUnderline then C.Font.Style := C.Font.Style + [fsUnderline];
end;

procedure TDHStyleLinkProp.Assign(Source: TPersistent);
begin
  if Source is TDHStyleLinkProp then
  begin
    Self.FFontColor := TDHStyleLinkProp(Source).FFontColor;
    Self.FBackColor := TDHStyleLinkProp(Source).FBackColor;
    Self.FUnderline := TDHStyleLinkProp(Source).FUnderline;
  end else
    inherited;
end;

function TDHStyleLinkProp.GetStored: Boolean;
begin
  Result := GetStoredFontColor
         or FUnderline
         or (FBackColor<>clNone);
end;

procedure TDzHTMLText.SetStyleLink(const Index: Integer;
  const Value: TDHStyleLinkProp);
begin
  case Index of
    1: FStyleLinkNormal.Assign(Value);
    2: FStyleLinkHover.Assign(Value);
  end;
end;

function TDzHTMLText.GetStoredStyleLink(const Index: Integer): Boolean;
begin
  Result := False;
  case Index of
    1: Result := FStyleLinkNormal.GetStored;
    2: Result := FStyleLinkHover.GetStored;
  end;
end;
{$ENDREGION}

{ TListToken }

function TListToken.GetLinkText(IEnd: Integer): String;
var I: Integer;
  T: TToken;
begin
  //returns the link display text where IEnd is Link Close tag Token on the list
  //so, it will start from the end until find the Link Open tag.

  Result := '';
  for I := IEnd-1 downto 0 do
  begin
    T := Items[I];
    if T.Kind = ttLink then Break; //should be open tag

    if T.Kind in [ttText, ttSpace] then
      Result := T.Text + Result;
  end;
end;

end.
