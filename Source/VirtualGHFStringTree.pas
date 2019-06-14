{ ----------------------------------------------------------- }
{ ----Purpose : VT With Groupheader and Footer. }
{ By      : Ir. G.W. van der Vegt }
{ For     : Fun }
{ Module  : VirtualGHFStringTree.pas }
{ Depends : VT 3.2.1 }
{ ----------------------------------------------------------- }
{ ddmmyyyy comment }
{ -------- ------------------------------------------------- }
{ 05062002-Initial version. }
{ -Footer Min/Maxwidth linked to VT Header. }
{ 06062002-Implemented Min/MaxWdith width for groupheader. }
{ -Set Fulldrag of THeadControls to False to prevent }
{ strange width problems when dragging exceeds }
{ MaxWidth. }
{ -Corrected some bugs. }
{ -Started on documentation. }
{ ----------------------------------------------------------- }
{ nr.    todo }
{ ------ -------------------------------------------------- }
{ 1.     Scan for missing 3.2.1 properties. }
{ ----------------------------------------------------------- }

{
  @abstract(Extends a TVirtualStringTree with a GroupHeader and Footer Control. )
  @author(G.W. van der Vegt <wvd_vegt@knoware.nl>)
  @created(Juli 05, 2002)
  @lastmod(Juli 06, 2002)
  This unit contains a TVirtualStringTree Descendant that can
  be linked to two THeaderControls that will act as a
  GroupHeader and a Footer. The Component takes care of the
  synchronized resizing of the columns, sections and controls.
  <P>
  Just drop a TVirtualGHFStringTree and up to two
  THeaderControls and link them to the TVirtualGHFStringTree.
  Then add columns to both THeaderControls and Columns to
  the TVirtualGHFStringTree's Header.
  <P>
  The Tag Value of the TVirtualGHFStringTree Header Columns is
  used to group the columns and link them to a GroupHeader's
  Section.
}

unit VirtualGHFStringTree;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  VirtualTrees, StdCtrls, Comctrls;

type
  { This TVirtualStringTree Descendant allows one to
    attach a GroupHeader and or Footer to a
    TVirtualStringTree.
    <P>
    Both GroupHeader and Footer are THeaderControl's.
    TVirtualGHFStringTree takes care of the synchronized
    resizing of all three components.
  }
  TVirtualGHFStringTree = class(TVirtualStringTree)
  private
    FGroupHeader: THeaderControl;
    FFooter: THeaderControl;
    function GetFooter: THeaderControl;
    function GetGroupHeader: THeaderControl;
    procedure SetFooter(const Value: THeaderControl);
    procedure SetGroupHeader(const Value: THeaderControl);
  protected
    { Description<P>
      Used for TreeOption in VirtualTreeView. }
    function GetOptionsClass: TTreeOptionsClass; override;
    { Description<P>
      Sets the name of the Component and renames the GroupHeader
      and Footer controls accordingly. Do not call it directly
      but use the name property instead.
      <P>
      Parameters<P>
      NewName :   The new name of the Component. }
    procedure SetName(const NewName: TComponentName); override;

    { Description<P>
      Responds to Resizing the component by re-aligning
      the GroupHeader and Footer controls accordingly. Do
      not call directly.
      <P>
      Parameters<P>
      Message :   The WM_SIZE Message. }
    procedure WMSize(var Message: TWMSize); message WM_SIZE;

    { Description<P>
      Responds to Moving the component by re-aligning
      the GroupHeader and Footer controls accordingly. Do
      not call directly.
      <P>
      Parameters<P>
      Message :   The WM_MOVE Message. }
    procedure WMMove(var Message: TWMMove); message WM_MOVE;

    { Description<P>
      Called when the component's loading is finished. It
      will re-align the GroupHeader and Footer controls.
      Do not call directly. }
    procedure Loaded; override;

    procedure DoColumnResize(Column: TColumnIndex); override;

    procedure UpdateHorizontalRange; override;

    { Description<P>
      Internally used to Resize the GroupHeader and Footer controls and
      update the MinWidth and Maxwith properties of both GroupHeader and Footer's
      Sections. Do not call directly. }
    procedure MyResize;

    { Description<P>
      Internally used to Resize the Columns and Sections.
      Do not call directly. }
    procedure ReAlignAll;

    { Description<P>
      Internally used to trap Column Resizing. Attached to
      the TVirtualStringTree's OnColumnResize Event. }
    procedure MyOnColumnResize(Sender: TVTHeader; Column: TColumnIndex);

    { Description<P>
      Internally used to trap Footer Section Resizing. Attached to
      the Footer's OnSectionTrack Event. }
    procedure MyOnFooterSectionTrack(HeaderControl: THeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState);

    { Description<P>
      Internally used to trap Group Header Section Resizing. Attached to
      the GroupHeader's OnSectionTrack Event. }
    procedure MyOnGroupHeaderSectionTrack(HeaderControl: THeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState);
  public
    constructor Create(AOwner: TComponent); override;
  published
    { Get/Sets the Footer value of the TVirtualGHFStringTree.
      The number of sections must be equal to the number of
      columns in the TVirtualGHFStringTree. MinWidth and MaxWidth
      are derived from the Header Columns.
      <P>
      Note<P>
      The Footer is renamed on basis of the TVirtualGHFStringTree's
      name to prevent problems with determining which THeaderControl belongs
      to which TVirtualGHFStringTree. }
    property Footer: THeaderControl read GetFooter write SetFooter;

    { Get/Sets the GroupHeader value of the TVirtualGHFStringTree.
      The Tag property of the HeaderColumn is used to determine
      which Header Columns belong to which GroupHeader Section.
      A group consists of adjacent Header Columns. The rightmost
      group(s) may be empty if their Indexes aren't used as the Tag Value
      in any Header Column. MinWidth and MaxWidth are derived from
      the Header Columns.
      <P>
      Note<P>
      The GroupHeader is renamed on basis of the TVirtualGHFStringTree's
      name to prevent problems with determining which THeaderControl belongs
      to which TVirtualGHFStringTree. }
    property GroupHeader: THeaderControl read GetGroupHeader write SetGroupHeader;
  end;

  { Description
    Standard Register Routine for this component.
    Registers TVirtualGHFStringTree to the 'Virtual Controls' tab of the component palette. }
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Virtual Controls', [TVirtualGHFStringTree]);
end;

function LineHeight(Canvas: TCanvas): Integer;
var
  tm: TEXTMETRIC;
begin
  with Canvas do
  begin
    GetTextmetrics(handle, tm);
    Result := tm.tmHeight + tm.tmExternalLeading;
  end;
end;

{ TVirtualGHFStringTree }

constructor TVirtualGHFStringTree.Create(AOwner: TComponent);
begin
  inherited;

  Header.Options := Header.Options + [hoVisible] - [hoRestrictDrag, hoDrag];
  BorderWidth := 0;
  BevelKind := bkNone;
  BorderStyle := bsNone;

  FGroupHeader := nil;
  FFooter := nil;
end;

function TVirtualGHFStringTree.GetOptionsClass: TTreeOptionsClass;
begin
  Result := inherited;
end;

procedure TVirtualGHFStringTree.MyResize;
begin
  if Assigned(FGroupHeader) then
  begin
    FGroupHeader.Left := Left + OffsetX;
    FGroupHeader.Width := Width - OffsetX;
    FGroupHeader.Height := Round(1.6 * LineHeight(FGroupHeader.Canvas)); // 1.9 = 25, 1.8 = 23, was 1.6 = 21
    FGroupHeader.Top := Top - Round(1.6 * LineHeight(FGroupHeader.Canvas));
  end;

  if Assigned(FFooter) then
  begin
    FFooter.Left := Left + OffsetX;
    FFooter.Width := Width - OffsetX;
    FFooter.Top := Self.Top + Self.Height;
    FFooter.Height := Round(2.6 * LineHeight(FFooter.Canvas)); // 34
  end;
end;

procedure TVirtualGHFStringTree.MyOnColumnResize(Sender: TVTHeader; Column: TColumnIndex);
var
  ndx, w, i: Integer;
begin
  ndx := Sender.Columns[Column].Tag;

  if not(Assigned(GroupHeader)) or (ndx >= GroupHeader.Sections.Count) then
    Exit;

  // Get Width of Group Header's columns
  w := 0;
  for i := 0 to Pred(Header.Columns.Count) do
    if (Sender.Columns[i].Tag = ndx) then
      Inc(w, Header.Columns[i].Width);
  GroupHeader.Sections[ndx].Width := w;
  GroupHeader.Update;

  if not(Assigned(Footer)) or (Header.Columns.Count <> Footer.Sections.Count) then
    Exit;

  for i := 0 to Pred(Header.Columns.Count) do
  begin
    Footer.Sections[i].MinWidth := Header.Columns[i].MinWidth;
    Footer.Sections[i].MaxWidth := Header.Columns[i].MaxWidth;
    Footer.Sections[i].Width := Header.Columns[i].Width;
  end;

  Footer.Update;
end;

procedure TVirtualGHFStringTree.ReAlignAll;
var
  i, j: TColumnIndex;
  MinW, MaxW: Integer;
begin
  if Assigned(GroupHeader) then
  begin
    // Loop through the Groupheaders Columns to calculated the Total MinWidth and MaxWidth
    for i := 0 to Pred(GroupHeader.Sections.Count) do
    begin
      MinW := -1;
      MaxW := -1;

      for j := 0 to Pred(Header.Columns.Count) do
        if (i = Header.Columns[j].Tag) then
        begin
          Inc(MinW, Header.Columns[j].MinWidth);
          Inc(MaxW, Header.Columns[j].MaxWidth);
        end;

      if (MinW <> -1) and (MaxW <> -1) then
      begin
        GroupHeader.Sections[i].MinWidth := MinW + 1;
        GroupHeader.Sections[i].MaxWidth := MaxW + 1;
      end;
    end;
  end;

  // Loop through the Header Columns to copy their MinWidth and MaxWidth to the Footer
  if Assigned(Footer) then
  begin
    Footer.Sections.BeginUpdate;
    for i := 0 to Pred(Header.Columns.Count) do
    begin
      Footer.Sections[i].MinWidth := Header.Columns[i].MinWidth;
      Footer.Sections[i].MaxWidth := Header.Columns[i].MaxWidth;
    end;
    Footer.Sections.EndUpdate;
  end;

  // Resize Every Column.
  for i := 0 to Pred(Header.Columns.Count) do
    MyOnColumnResize(Header, i);
end;

procedure TVirtualGHFStringTree.MyOnFooterSectionTrack(HeaderControl: THeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState);
begin
  // Strange Effects when MaxWidth is Exceeded during Drag. Width seem to be Starting at zero again.
  Header.Columns[Section.Index].Width := Width;
  HeaderControl.Repaint;
  MyOnColumnResize(Header, Section.Index);
end;

procedure TVirtualGHFStringTree.MyOnGroupHeaderSectionTrack(HeaderControl: THeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState);
var
  d, i, gr, grw, sw: Integer;
  found: Boolean;
  v, mid, sid: Integer;
begin
  // Strange Effects when MaxWidth is Exceeded during Drag. Width seem to be Starting at zero again.
  gr := Section.Index;

  found := False;
  grw := 0;
  for i := 0 to Pred(Header.Columns.Count) do
    if (Header.Columns[i].Tag = gr) then
    begin
      Inc(grw, Header.Columns[i].Width);
      found := True;
    end;

  Section.Width := Width;

  // Prevent Resizing when there are no columns for this GroupHeader Section.
  if not found then
    Exit;

  OutputDebugString(PChar(IntToStr(Width) + '+' + IntToStr(grw) + '+' + IntToStr(gr)));

  sw := Width;
  d := Abs(grw - sw);

  // Now loop and Increment either the smallest or Decrement the largest column
  // until the sizes match.
  Header.Columns.BeginUpdate;
  repeat
    found := False;

    if (d > 0) then
    begin
      if (grw - sw) > 0 then
      begin
        // Find largest
        v := -1;
        mid := 0;
        for i := 0 to Pred(Header.Columns.Count) do
          if (Header.Columns[i].Tag = gr) and (v < Header.Columns[i].Width) then
          begin
            v := Header.Columns[i].Width;
            mid := i;
          end;

        if (Header.Columns[mid].Width > Header.Columns[mid].MinWidth) then
        begin
          Header.Columns[mid].Width := Header.Columns[mid].Width - 1;
          Dec(d);
          Dec(grw);
          found := True;
        end;
      end
      else
      begin
        // Find smallest
        v := maxint;
        sid := 0;
        for i := 0 to Pred(Header.Columns.Count) do
          if (Header.Columns[i].Tag = gr) and (v > Header.Columns[i].Width) then
          begin
            v := Header.Columns[i].Width;
            sid := i;
          end;

        if (Header.Columns[sid].Width < Header.Columns[sid].MaxWidth) then
        begin
          Header.Columns[sid].Width := Header.Columns[sid].Width + 1;
          Dec(d);
          Inc(grw);
          found := True;
        end;
      end;
    end
  until (d = 0) or not found;

  Header.Columns.EndUpdate;
  Update;

  // Prevent Resizing when there's no Footer
  if not(Assigned(Footer)) or (Header.Columns.Count <> Footer.Sections.Count) then
    Exit;

  Footer.Sections.BeginUpdate;
  for i := 0 to Pred(Header.Columns.Count) do
    Footer.Sections[i].Width := Header.Columns[i].Width;
  Footer.Sections.EndUpdate;
  Footer.Update;
end;

procedure TVirtualGHFStringTree.SetName(const NewName: TComponentName);
begin
  inherited;

  // Rename the headercontrols so we can see to who they belong.
  // Makes it ieasier to find the newly dropped ones with their default names.
  if Assigned(FGroupHeader) then
    FGroupHeader.Name := NewName + '_GroupHeader';
  if Assigned(FFooter) then
    FFooter.Name := NewName + '_Footer';

  // Update after the components name is changed won't hurt.
  MyResize;
  ReAlignAll;
end;

procedure TVirtualGHFStringTree.UpdateHorizontalRange;
begin
  inherited;

  MyResize;
end;

procedure TVirtualGHFStringTree.Loaded;
begin
  inherited;

  // We need an update after the component is loaded to align everything.
  MyResize;
  ReAlignAll;
end;

function TVirtualGHFStringTree.GetGroupHeader: THeaderControl;
begin
  Result := FGroupHeader;
end;

procedure TVirtualGHFStringTree.SetGroupHeader(const Value: THeaderControl);
begin
  if Assigned(Value) then
  begin
    // Make sure to change some properties so we don't get problems.
    FGroupHeader := Value;
    FGroupHeader.Align := alNone;
    FGroupHeader.DoubleBuffered := True;

    // Prevent Strange Effects when MaxWidth is Exceeded during Drag. Width seem to be Starting at zero again.
    FGroupHeader.FullDrag := False;
    FGroupHeader.OnSectionTrack := MyOnGroupHeaderSectionTrack;

    // Rename the headercontrol so we can see to who they belong.
    // Makes it easier to find the newly dropped ones with their default names.
    FGroupHeader.Name := Name + '_GroupHeader';

    // Re-arrange all when adding or removing a header
    MyResize;
    ReAlignAll;
  end
  else
  begin
    FGroupHeader.OnSectionTrack := nil;
    FGroupHeader := Value;
  end;
end;

procedure TVirtualGHFStringTree.DoColumnResize(Column: TColumnIndex);
begin
  inherited;
  MyOnColumnResize(Self.Header, Column);
end;

function TVirtualGHFStringTree.GetFooter: THeaderControl;
begin
  Result := FFooter;
end;

procedure TVirtualGHFStringTree.SetFooter(const Value: THeaderControl);
begin
  if Assigned(Value) then
  begin
    // Make sure to change some properties so we don't get problems.
    FFooter := Value;
    FFooter.Align := alNone;
    FFooter.DoubleBuffered := True;

    // Strange Effects when MaxWidth is Exceeded during Drag. Width seem to be Starting at zero again.
    FFooter.FullDrag := False;
    FFooter.OnSectionTrack := MyOnFooterSectionTrack;

    // Rename the headercontrols so we can see to who they belong.
    // Makes it easier to find the newly dropped ones with their default names.
    FFooter.Name := Name + '_Footer';

    // Re-arrange all when adding or removing a footer
    MyResize;
    ReAlignAll;
  end
  else
  begin
    FFooter.OnSectionTrack := nil;
    FFooter := Value;
  end;
end;

procedure TVirtualGHFStringTree.WMMove(var Message: TWMMove);
begin
  inherited;

  // Re-arrange all when moving the component.
  MyResize;
  ReAlignAll;
end;

procedure TVirtualGHFStringTree.WMSize(var Message: TWMSize);
begin
  inherited;

  // Re-arrange all when sizing the component.
  MyResize;
  ReAlignAll;
end;

end.
