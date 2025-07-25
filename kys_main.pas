﻿unit kys_main;

{$IFDEF fpc}
//{$MODE Delphi}
{$ELSE}
{$ENDIF}
{
  All Heros in Kam Yung's Stories - The Replicated Edition

  Created by S.weyl in 2008 May.
  No Copyright (C) reserved.

  You can build it by Delphi with JEDI-SDL support.

  This resouce code file which is not perfect so far,
  can be modified and rebuilt freely,
  or translate it to another programming language.
  But please keep this section when you want to spread a new vision. Thanks.
  Note: it must not be a good idea to use this as a pascal paradigm.

}

{
  任何人获得这份代码之后, 均可以自由增删功能, 重新
  编译, 或译为其他语言. 但请保留本段文字.
}

interface

uses

  {$IFDEF fpc}
  LConvEncoding,
  LCLType,
  LCLIntf,
  {$ELSE}
  {$ENDIF}
  {$IFDEF ANDROID}
  jni,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  kys_type,
  SysUtils,
  StrUtils,
  Dialogs,
  Math,
  SDL3_TTF,
  SDL3,
  SDL3_image,
  iniFiles,
  bass,
  Generics.Collections;

//程序重要子程
procedure Run;
procedure Quit;
procedure SetMODVersion;
procedure ReadFiles;

//游戏开始画面, 行走等
procedure Start;
procedure StartAmi;
function InitialRole: boolean;
procedure LoadR(num: integer);
procedure SaveR(num: integer);
function WaitAnyKey: integer;
procedure Walk;
function CanWalk(x, y: integer): boolean;
function CheckEntrance: boolean;
function UpdateSceneAmi(param: pointer; timerid: TSDL_TimerID; interval: uint32): uint32; cdecl;
function WalkInScene(Open: integer): integer;
procedure FindWay(x1, y1: integer);
procedure Moveman(x1, y1, x2, y2: integer);
procedure ShowSceneName(snum: integer);
function CanWalkInScene(x, y: integer): boolean; overload;
function CanWalkInScene(x1, y1, x, y: integer): boolean; overload;
function CheckEvent1: boolean;
procedure CheckEvent3;

//选单子程
function CommonMenu(x, y, w, max: integer; menuString: array of utf8string): integer; overload;
function CommonMenu(x, y, w, max, default: integer; menuString: array of utf8string): integer; overload;
function CommonMenu(x, y, w, max: integer; menuString, menuEngString: array of utf8string): integer; overload;
function CommonMenu(x, y, w, max, default: integer; menuString, menuEngString: array of utf8string): integer; overload;
function CommonMenu(x, y, w, max, default: integer; menuString, menuEngString: array of utf8string; fn: TPInt1): integer; overload;
procedure ShowCommonMenu(x, y, w, max, menu: integer; menuString: array of utf8string); overload;
procedure ShowCommonMenu(x, y, w, max, menu: integer; menuString, menuEngString: array of utf8string); overload;
function CommonScrollMenu(x, y, w, max, maxshow: integer; menuString: array of utf8string): integer; overload;
function CommonScrollMenu(x, y, w, max, maxshow: integer; menuString, menuEngString: array of utf8string): integer; overload;
procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer; menuString, menuEngString: array of utf8string);
function CommonMenu2(x, y, w: integer; menuString: array of utf8string): integer;
procedure ShowCommonMenu2(x, y, w, menu: integer; menuString: array of utf8string);
function SelectOneTeamMember(x, y: integer; str: utf8string; list1, list2: integer): integer;
procedure MenuEsc;
procedure ShowMenu(menu: integer);
procedure MenuMedcine;
procedure MenuMedPoison;
function MenuItem: boolean;
function ReadItemList(ItemType: integer): integer;
procedure ShowMenuItem(row, col, x, y, atlu: integer);
procedure DrawItemFrame(x, y: integer);
procedure UseItem(inum: integer);
function CanEquip(rnum, inum: integer): boolean;
procedure MenuStatus;
procedure ShowStatusByTeam(tnum: integer);
procedure ShowStatus(rnum: integer); overload;
procedure ShowStatus(rnum, x, y: integer); overload;
procedure ShowSimpleStatus(rnum, x, y: integer);
procedure MenuLeave;
procedure MenuSystem;
procedure ShowMenuSystem(menu: integer);
procedure MenuLoad;
function MenuLoadAtBeginning: integer;
procedure MenuSave;
procedure MenuQuit;

//医疗, 解毒, 使用物品的效果等
function EffectMedcine(role1, role2: integer): integer;
function EffectMedPoison(role1, role2: integer): integer;
function EatOneItem(rnum, inum: integer; times: integer = 1; display: integer = 1): integer;

//事件系统
procedure CallEvent(num: integer);

//云的初始化和再次出现
procedure CloudCreate(num: integer);
procedure CloudCreateOnSide(num: integer);

function IsCave(snum: integer): boolean;

procedure teleport();

function SDL_GetAndroidExternalStoragePath(): pansichar; cdecl; external 'libSDL3.so';

implementation

uses
  kys_script,
  kys_event,
  kys_engine,
  kys_battle,
  kys_draw;

//初始化字体, 音效, 视频, 启动游戏
procedure Run;
var
  Text: PSDL_Surface;
  word: array [0 .. 1] of uint16; //= (32, 0);
  tempcolor: TSDL_Color;
  str: utf8string;
  current, temp: integer;
  ini: TIniFile;
  render_str: putf8char = 'direct3d';
begin
  {$IFDEF windows}
  SetConsoleOutputCP(65001);
  {$ENDIF}
  word[0] := 32;
  {$IFDEF UNIX}
  AppPath := ExtractFilePath(ParamStr(0));
  {$ELSE}
  AppPath := '';
  {$ENDIF}
  {$IFDEF android}
  AppPath := '/sdcard/kys-pascal/';
  if (not fileexists(AppPath + 'kysmod.ini')) and (not fileexists(AppPath + 'games.ini')) then
    AppPath := SDL_GetAndroidExternalStoragePath() + '/';
  //for i := 1 to 4 do
  //AppPath:= ExtractFileDir(AppPath);
  str := SDL_GetAndroidExternalStoragePath() + '/place_game_here';
  //if not fileexists(str) then
  FileClose(filecreate(str));
  SDL_SetHint(SDL_HINT_ORIENTATIONS, 'LandscapeLeft LandscapeRight');
  CellPhone := 1;
  //SDL_RequestAndroidPermission('MANAGE_EXTERNAL_STORAGE');
  //SDL_RequestAndroidPermission('android.permission.WRITE_EXTERNAL_STORAGE');
  render_str := '';
  {$ENDIF}

  //CellPhone := 1;

  if fileexists(AppPath + 'games.ini') then
  begin
    try
      ini := TIniFile.Create(AppPath + 'games.ini');
      current := ini.ReadInteger('games', 'current', 0);
      str := ini.ReadString('games', IntToStr(current), ':');
      current := pos('kys', str);
      str := copy(str, current, 20);
      AppPath := AppPath + str + '/';
    finally
      ini.Free;
    end;
  end;

  AppPathCommon := AppPath + '../kys-pascal/';

  ReadFiles;

  SetMODVersion;

  TTF_Init();
  str := AppPath + CHINESE_FONT;
  if (not fileexists(str)) then str := AppPathCommon + CHINESE_FONT;
  font := TTF_OpenFont(putf8char(str), CHINESE_FONT_SIZE);

  str := AppPath + ENGLISH_FONT;
  if (not fileexists(str)) then str := AppPathCommon + ENGLISH_FONT;
  engfont := TTF_OpenFont(putf8char(str), ENGLISH_FONT_SIZE);

  //此处测试中文字体的空格宽度
  Text := TTF_RenderText_solid(font, @word[0], 1, tempcolor);
  //writeln(SDL_geterror());
  //writeln(text.w);
  CHNFONT_SPACEWIDTH := Text.w;
  //CHNFONT_SPACEWIDTH := 10;
  SDL_DestroySurface(Text);

  //初始化音频系统
  //SDL_Init(SDL_INIT_AUDIO);
  //Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 16384);
  SoundFlag := 0;
  if SOUND3D = 1 then
    SoundFlag := BASS_DEVICE_3D or SoundFlag;
  BASS_Init(-1, 22050, SoundFlag, 0, nil);

  //初始化视频系统
  Randomize;
  //SDL_Init(SDL_INIT_VIDEO);
  if not SDL_Init(SDL_INIT_VIDEO) then
  begin
    //MessageBox(0, putf8char(Format('Couldn''t initialize SDL : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    exit;
  end;

  //SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, '1');
  //SDL_SetHint(SDL_HINT_IME_SHOW_UI, '1');

  ScreenFlag := SDL_WINDOW_RESIZABLE;
  window := SDL_CreateWindow(putf8char(TitleString), RESOLUTIONX, RESOLUTIONY, ScreenFlag);
  SDL_GetWindowSize(window, @RESOLUTIONX, @RESOLUTIONY);

  if (CellPhone = 1) then
  begin
    if (RESOLUTIONY > RESOLUTIONX) then
    begin
      ScreenRotate := 0;
      temp := RESOLUTIONY;
      RESOLUTIONY := RESOLUTIONX;
      RESOLUTIONX := temp;
    end;
    //SDL_WarpMouseInWindow(window, RESOLUTIONX, RESOLUTIONY);
  end;

  //SDL_WM_SetCaption(putf8char(TitleString), 's.weyl');
  SDL_SetHint(SDL_HINT_RENDER_DRIVER, 'direct3d,vulkan,direct3d12,direct3d11,opengl');
  render := SDL_CreateRenderer(window, render_str);
  screen := SDL_CreateSurface(CENTER_X * 2, CENTER_Y * 2, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  screenTex := SDL_CreateTexture(render, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, CENTER_X * 2, CENTER_Y * 2);
  //prescreen := SDL_CreateRGBSurface(ScreenFlag, CENTER_X * 2, CENTER_Y * 2, 32, RMask, GMask, BMask, 0);
  //prescreen := SDL_DisplayFormat(screen);
  freshscreen := SDL_CreateSurface(CENTER_X * 2, CENTER_Y * 2, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));

  ImageWidth := (36 * 32 + CENTER_X) * 2;
  ImageHeight := (18 * 32 + CENTER_Y) * 2;

  ImgScene := SDL_CreateSurface(ImageWidth, ImageHeight, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  //ImgScene := SDL_DisplayFormat(ImgScene);
  ImgSceneBack := SDL_CreateSurface(ImageWidth, ImageHeight, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  ImgBField := SDL_CreateSurface(ImageWidth, ImageHeight, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  ImgBBuild := SDL_CreateSurface(ImageWidth, ImageHeight, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  SDL_SetSurfaceColorKey(ImgScene, False, 1);
  SDL_SetSurfaceColorKey(ImgSceneBack, True, 1);
  SDL_SetSurfaceColorKey(ImgBField, False, 1);
  SDL_SetSurfaceColorKey(ImgBBuild, True, 1);
  setlength(BlockImg, ImageWidth * ImageHeight);
  setlength(BlockImg2, ImageWidth * ImageHeight);

  if (window = nil) then
  begin
    SDL_Quit;
    halt(1);
  end;

  InitialScript;
  InitialMusic;

  SDL_AddEventWatch(@EventFilter, nil);
  mutex := SDL_CreateMutex();

  SDL_AddTimer(200, UpdateSceneAmi, nil);

  Start;

  Quit;

end;

//关闭所有已打开的资源, 退出
procedure Quit;
begin
  FreeAllSurface;
  DestroyScript;
  TTF_CloseFont(font);
  TTF_CloseFont(engfont);
  TTF_Quit;
  SDL_DestroyMutex(mutex);
  SDL_Quit;
  BASS_Free;
  halt(1);
  exit;

end;

procedure SetMODVersion;
var
  filename: utf8string;
  Kys_ini: TIniFile;
begin

  setlength(Music, 24);
  setlength(Esound, 53);
  setlength(Asound, 25);
  StartMusic := 16;
  TitleString := 'All Heros in Kam Yung''s Stories - Replicated Edition';
  OpenPicPosition.x := CENTER_X - 320;
  OpenPicPosition.y := CENTER_Y - 220;
  TitlePosition.x := OpenPicPosition.x + 275;
  TitlePosition.y := OpenPicPosition.y + 125;

  case MODVersion of
    0:
    begin

    end;
    11:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - A Pig';
      TitlePosition.y := 270;
      OpenPicPosition.y := OpenPicPosition.y + 20;
      CENTER_Y := 240;
    end;
    12:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - We Are Dragons';
      setlength(Asound, 37);
      TitlePosition.x := 200;
      TitlePosition.y := 250;
    end;
    21:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Books';
      TitlePosition.x := 275;
      TitlePosition.y := 285;
      setlength(Esound, 59);
    end;
    22:
    begin
      TitleString := 'Why I have to go after a pineapple in the period of Three Kingdoms??';
      MAX_ITEM_AMOUNT := 456;
      setlength(Music, 38);
      StartMusic := 37;
      CENTER_Y := 240;
    end;
    23:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Four Dreams';
      //TitlePosition.x := 275;
      TitlePosition.y := 165;
      setlength(Music, 25);
      setlength(Esound, 84);
      StartMusic := 24;
      CENTER_Y := 240;
    end;
    31:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Wider Rivers and Deeper Lakes';
      setlength(Esound, 99);
      setlength(Asound, 71);
    end;
    41:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Here is PTT';
      TitlePosition.y := 255;
      OpenPicPosition.y := OpenPicPosition.y + 20;
      CENTER_Y := 240;
    end;
    51:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - An Prime Minister of Tang';
      //CHINESE_FONT_SIZE:= 16;
      //ENGLISH_FONT_SIZE:= 15;
    end;
    71:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Books from Heaven';
      TitlePosition.x := 60;
      TitlePosition.y := 270;
      OpenPicPosition.y := OpenPicPosition.y + 20;
      MAX_ITEM_AMOUNT := 400;
      setlength(Esound, 207);
      setlength(Asound, 37);
    end;
    81:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Awaking of Dragons';
      setlength(Music, 999);
      TitlePosition.x := 200;
      TitlePosition.y := 250;
    end;
    91:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - What''s Loving';
      setlength(Music, 999);
    end;
  end;

  {$IFDEF fpc}
  filename := AppPath + 'kysmod.ini';
  {$ELSE}
  filename := ExtractFilePath(ParamStr(0)) + 'kysmod.ini';
  {$ENDIF}
  Kys_ini := TIniFile.Create(filename);
  try
    //RESOLUTIONX := Kys_ini.ReadInteger('system', 'RESOLUTIONX', CENTER_X * 2);
    //RESOLUTIONY := Kys_ini.ReadInteger('system', 'RESOLUTIONY', CENTER_Y * 2);
  finally
    Kys_ini.Free;
  end;

end;

//读取必须的文件
procedure ReadFiles;
var
  grp, idx, tnum, len, col, i, k: integer;
  filename: utf8string;
  Kys_ini: TIniFile;
  LoadPNGTilesThread: PSDL_Thread;
begin

  {$IFDEF fpc}
  filename := AppPath + 'kysmod.ini';
  {$ELSE}
  filename := ExtractFilePath(ParamStr(0)) + 'kysmod.ini';
  {$ENDIF}
  Kys_ini := TIniFile.Create(filename);

  try
    ITEM_BEGIN_PIC := Kys_ini.ReadInteger('constant', 'ITEM_BEGIN_PIC', 3501);
    MAX_HEAD_NUM := Kys_ini.ReadInteger('constant', 'MAX_HEAD_NUM', 189);
    BEGIN_EVENT := Kys_ini.ReadInteger('constant', 'BEGIN_EVENT', 691);
    BEGIN_SCENE := Kys_ini.ReadInteger('constant', 'BEGIN_SCENE', 70);
    BEGIN_Sx := Kys_ini.ReadInteger('constant', 'BEGIN_Sx', 20);
    BEGIN_Sy := Kys_ini.ReadInteger('constant', 'BEGIN_Sy', 19);
    SOFTSTAR_BEGIN_TALK := Kys_ini.ReadInteger('constant', 'SOFTSTAR_BEGIN_TALK', 2547);
    SOFTSTAR_NUM_TALK := Kys_ini.ReadInteger('constant', 'SOFTSTAR_NUM_TALK', 18);
    MAX_PHYSICAL_POWER := Kys_ini.ReadInteger('constant', 'MAX_PHYSICAL_POWER', 100);
    BEGIN_WALKPIC := Kys_ini.ReadInteger('constant', 'BEGIN_WALKPIC', 2501);
    MONEY_ID := Kys_ini.ReadInteger('constant', 'MONEY_ID', 174);
    COMPASS_ID := Kys_ini.ReadInteger('constant', 'COMPASS_ID', 182);
    BEGIN_LEAVE_EVENT := Kys_ini.ReadInteger('constant', 'BEGIN_LEAVE_EVENT', 950);
    BEGIN_BATTLE_ROLE_PIC := Kys_ini.ReadInteger('constant', 'BEGIN_BATTLE_ROLE_PIC', 2553);
    MAX_LEVEL := Kys_ini.ReadInteger('constant', 'MAX_LEVEL', 30);
    MAX_WEAPON_MATCH := Kys_ini.ReadInteger('constant', 'MAX_WEAPON_MATCH', 7);
    MIN_KNOWLEDGE := Kys_ini.ReadInteger('constant', 'MIN_KNOWLEDGE', 80);
    MAX_HP := Kys_ini.ReadInteger('constant', 'MAX_HP', 999);
    MAX_MP := Kys_ini.ReadInteger('constant', 'MAX_MP', 999);
    LIFE_HURT := Kys_ini.ReadInteger('constant', 'LIFE_HURT', 10);
    POISON_HURT := Kys_ini.ReadInteger('constant', 'POISON_HURT', 10);
    MED_LIFE := Kys_ini.ReadInteger('constant', 'MED_LIFE', 4);
    NOVEL_BOOK := Kys_ini.ReadInteger('constant', 'NOVEL_BOOK', 144);
    MAX_ADD_PRO := Kys_ini.ReadInteger('constant', 'MAX_ADD_PRO', 0);

    BATTLE_SPEED := Kys_ini.ReadInteger('system', 'BATTLE_SPEED', 10);
    WALK_SPEED := Kys_ini.ReadInteger('system', 'WALK_SPEED', 10);
    WALK_SPEED2 := Kys_ini.ReadInteger('system', 'WALK_SPEED2', WALK_SPEED);
    SMOOTH := Kys_ini.ReadInteger('system', 'SMOOTH', 1);
    SIMPLE := Kys_ini.ReadInteger('system', 'SIMPLE', 1);
    //CENTER_X := Kys_ini.ReadInteger('system', 'CENTER_X', 320);
    //CENTER_Y := Kys_ini.ReadInteger('system', 'CENTER_Y', 220);
    //RESOLUTIONX := Kys_ini.ReadInteger('system', 'RESOLUTIONX', CENTER_X * 2);
    //RESOLUTIONY := Kys_ini.ReadInteger('system', 'RESOLUTIONY', CENTER_Y * 2);
    VOLUME := Kys_ini.ReadInteger('music', 'VOLUME', 30);
    VOLUMEWAV := Kys_ini.ReadInteger('music', 'VOLUMEWAV', 30);
    SOUND3D := Kys_ini.ReadInteger('music', 'SOUND3D', 1);
    MMAPAMI := Kys_ini.ReadInteger('system', 'MMAPAMI', 1);
    //SCENEAMI := Kys_ini.ReadInteger('system', 'SCENEAMI', 2);
    SEMIREAL := Kys_ini.ReadInteger('system', 'SEMIREAL', 0);
    MODVersion := Kys_ini.ReadInteger('system', 'MODVersion', 0);
    CHINESE_FONT_SIZE := Kys_ini.ReadInteger('system', 'CHINESE_FONT_SIZE', 20);
    ENGLISH_FONT_SIZE := Kys_ini.ReadInteger('system', 'ENGLISH_FONT_SIZE', 19);
    KDEF_SCRIPT := Kys_ini.ReadInteger('system', 'KDEF_SCRIPT', 1);
    NIGHT_EFFECT := Kys_ini.ReadInteger('system', 'NIGHT_EFFECT', 0);
    //EXIT_GAME := Kys_ini.ReadInteger('system', 'EXIT_GAME', 1);
    PNG_TILE := Kys_ini.ReadInteger('system', 'PNG_TILE', 0);
    TRY_FIND_GRP := Kys_ini.ReadInteger('system', 'TRY_FIND_GRP', 0);
    EXPAND_GROUND := Kys_ini.ReadInteger('system', 'EXPAND_GROUND', 0);
    WMP_4_PIC := Kys_ini.ReadInteger('system', 'WMP_4_PIC', 0);
    if CellPhone <> 0 then
    begin
      ShowVirtualKey := Kys_ini.ReadInteger('system', 'Virtual_Key', 1);
      VirtualKeyX := Kys_ini.ReadInteger('system', 'Virtual_Key_X', 100);
      VirtualKeyY := Kys_ini.ReadInteger('system', 'Virtual_Key_Y', 250);
      if FileExists(AppPath + 'resource/u.png') then
      begin
        VirtualKeyU := IMG_Load(putf8char(checkFileName('resource/u.png')));
        VirtualKeyD := IMG_Load(putf8char(checkFileName('resource/d.png')));
        VirtualKeyL := IMG_Load(putf8char(checkFileName('resource/l.png')));
        VirtualKeyR := IMG_Load(putf8char(checkFileName('resource/r.png')));
        VirtualKeyA := IMG_Load(putf8char(checkFileName('resource/a.png')));
        VirtualKeyB := IMG_Load(putf8char(checkFileName('resource/b.png')));
      end
      else
        ShowVirtualKey := 0;
    end
    else
      ShowVirtualKey := 0;

    if (not FileExists(AppPath + 'resource/mmap/index.ka')) and (not FileExists(AppPath + 'resource/mmap.imz')) then
      PNG_TILE := 0;

    for i := 43 to 58 do
    begin
      MaxProList[i] := Kys_ini.ReadInteger('constant', 'MaxProList' + IntToStr(i), 100);
    end;

    if LIFE_HURT = 0 then
      LIFE_HURT := 1;
    if POISON_HURT = 0 then
      POISON_HURT := 1;

  finally
    Kys_ini.Free;
  end;

  ReadFileToBuffer(@ACol[0], AppPath + 'resource/mmap.col', 768, 0);
  move(ACol[0], ACol1[0], 768);
  move(ACol[0], ACol2[0], 768);

  ReadFileToBuffer(@Earth[0, 0], AppPath + 'resource/earth.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@surface[0, 0], AppPath + 'resource/surface.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@Building[0, 0], AppPath + 'resource/building.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@Buildx[0, 0], AppPath + 'resource/buildy.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@Buildy[0, 0], AppPath + 'resource/buildx.002', 480 * 480 * 2, 0);

  ReadFileToBuffer(@leavelist[0], AppPath + 'list/leave.bin', 200, 0);
  ReadFileToBuffer(@effectlist[0], AppPath + 'list/effect.bin', 400, 0);
  ReadFileToBuffer(@leveluplist[0], AppPath + 'list/levelup.bin', 200, 0);

  ReadFileToBuffer(@matchlist[0], AppPath + 'list/match.bin', MAX_WEAPON_MATCH * 3 * 2, 0);

  LoadIdxGrp('resource/kdef.idx', 'resource/kdef.grp', KIdx, KDef);
  LoadIdxGrp('resource/talk.idx', 'resource/talk.grp', TIdx, TDef);

  setlength(HeadSurface, 999);
  setlength(ItemSurface, 999);
  fonts := TDictionary<integer, PSDL_Surface>.Create;

end;

//Main game.
//显示开头画面
procedure Start;
var
  menu, menup, i, col, i1, i2, x, y, k: integer;
  Selected: boolean;
begin
  PlayMP3(StartMusic, -1);

  where := 3;
  Redraw;

  if PNG_TILE > 0 then
  begin
    LoadPNGTiles('resource/title', TitlePNGIndex, TitlePNGTile, 1);
    DrawTitlePic(8, TitlePosition.x, TitlePosition.y + 20);
  end;

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  ReadTiles;

  begin_time := random(1440);
  now_time := begin_time;

  for i1 := 0 to 479 do
    for i2 := 0 to 479 do
      Entrance[i1, i2] := -1;

  //SDL_EnableKeyRepeat(0, 10);
  MStep := 0;
  FULLSCREEN := 0;
  menu := 0;
  setlength(Cloud, CLOUD_AMOUNT);
  for i := 0 to CLOUD_AMOUNT - 1 do
  begin
    CloudCreate(i);
  end;

  x := TitlePosition.x;
  y := TitlePosition.y;
  Redraw;
  DrawTitlePic(0, x, y);
  DrawTitlePic(menu + 1, x, y + menu * 20);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  //事件等待
  Selected := False;
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of //键盘事件
      SDL_EVENT_KEY_UP:
      begin
        if ((event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE)) then
        begin
          Selected := True;
        end;
        //按下方向键上
        if event.key.key = SDLK_UP then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 2;
          DrawTitlePic(0, x, y);
          DrawTitlePic(menu + 1, x, y + menu * 20);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        //按下方向键下
        if event.key.key = SDLK_DOWN then
        begin
          menu := menu + 1;
          if menu > 2 then
            menu := 0;
          DrawTitlePic(0, x, y);
          DrawTitlePic(menu + 1, x, y + menu * 20);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
      //按下鼠标(UP表示抬起按键才执行)
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_LEFT) and (round(event.button.x / (RESOLUTIONX / screen.w)) > x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + 80) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + 60) then
        begin
          Selected := True;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - y) div 20;
        end;
      end;
      //鼠标移动
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) > x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + 80) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + 60) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - y) div 20;
          if menu <> menup then
          begin
            DrawTitlePic(0, x, y);
            DrawTitlePic(menu + 1, x, y + menu * 20);
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
      end;
    end;
    if Selected then
    begin
      case menu of
        2: break;
        1:
        begin
          if MenuLoadAtBeginning >= 0 then
          begin
            //redraw;
            //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            CurEvent := -1; //when CurEvent=-1, Draw scene by Sx, Sy. Or by Cx, Cy.
            if where = 1 then
            begin
              WalkInScene(0);
            end;
            Walk;
            //menu := -1;
          end;
        end;
        0:
        begin
          Selected := InitialRole;
          if Selected then
          begin
            CurScene := BEGIN_SCENE;
            CurEvent := -1;
            if CurScene >= 0 then
              WalkInScene(1)
            else
              where := 0;
            Walk;
            //menu := -1;
          end;
        end;
      end;
      Redraw;
      DrawTitlePic(0, x, y);
      DrawTitlePic(menu + 1, x, y + menu * 20);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      Selected := False;
    end;
  end;

end;

//开头字幕
procedure StartAmi;
var
  x, y, i, len: integer;
  str, str1: utf8string;
  p: integer;
begin
  instruct_14;
  Redraw;
  i := FileOpen(AppPath + 'list/start.txt', fmOpenRead);
  len := FileSeek(i, 0, 2);
  FileSeek(i, 0, 0);
  setlength(str, len + 1);
  FileRead(i, str[1], len);
  str[len + 1] := #13;
  FileClose(i);
  p := 1;
  x := 30;
  y := 80;
  DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
  for i := 1 to len + 1 do
  begin
    if str[i] = utf8char(10) then
      str[i] := ' ';
    if str[i] = utf8char(13) then
    begin
      str[i] := utf8char(0);
      str1 := midstr(str, p, i - p);
      DrawShadowText(screen, str1, x, y, ColColor($FF), ColColor($FF));
      p := i + 1;
      y := y + 25;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;
    if str[i] = utf8char($2A) then
    begin
      str[i] := ' ';
      y := 80;
      Redraw;
      WaitAnyKey;
      DrawRectangleWithoutFrame(screen, 0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
    end;
  end;
  WaitAnyKey;
  instruct_14;
  //instruct_13;

end;

//初始化主角属性
function InitialRole: boolean;
var
  i: integer;
  p: array [0 .. 14] of integer;
  str, str0: utf8string;
  str1, str2, tempname: utf8string;
  input_name, homename: utf8string;
  p0, p1: putf8char;
  named: boolean;
  r: TSDL_Rect;
begin
  LoadR(0);
  //显示输入姓名的对话框
  //form1.ShowModal;
  //str := form1.edit1.text;
  str1 := '請輸入主角之姓名';
  //name := InputBox('Enter name', str1, '我是主角');
  where := 3;
  Redraw;
  tempname := '我是主角';
  homename := '主角的家';
  //for i := 0 to 4 do
  //  Rrole[0].Data[4 + i] := 0;
  str := str1;
  DrawTextWithRect(str1, CENTER_X - 83, CENTER_Y - 30, 166, ColColor($21), ColColor($23));
  named := True;
  input_name := CP950toutf8(Rrole[0].Name);
  named := EnterString(input_name, CENTER_X - 43, CENTER_Y + 10, 86, 100);
  if named then
  begin
    if input_name = '' then
    begin
      input_name := CP950toutf8(Rrole[0].Name);
    end;
    input_name := Simplified2Traditional(input_name);
    str1 := UTF8ToCP950(input_name);
    if (length(str1) in [1 .. 7]) and (input_name <> ' ') then
      homename := input_name + '居';
    str2 := UTF8ToCP950(homename);
    p0 := @Rrole[0].Name;
    p1 := @str1[1];
    for i := 0 to 4 do
      Rrole[0].Data[4 + i] := 0;
    for i := 0 to 7 do
    begin
      (p0 + i)^ := (p1 + i)^;
    end;

    if (MODVersion <> 22) and (MODVersion <> 11) and (MODVersion <> 12) and (MODVersion <> 91) then
    begin
      p0 := @Rscene[BEGIN_SCENE].Name;
      p1 := @str2[1];
      for i := 0 to 4 do
        Rscene[BEGIN_SCENE].Data[1 + i] := 0;
      for i := 0 to 8 do
      begin
        (p0 + i)^ := (p1 + i)^;
      end;
    end;

    Redraw;

    str := '資質';
    repeat
      if MODVersion <> 21 then
      begin
        Rrole[0].MaxHP := 25 + random(26);
        Rrole[0].CurrentHP := Rrole[0].MaxHP;
        Rrole[0].MaxMP := 25 + random(26);
        Rrole[0].CurrentMP := Rrole[0].MaxMP;
        Rrole[0].MPType := random(2);
        Rrole[0].IncLife := 1 + random(10);

        Rrole[0].Attack := 25 + random(6);
        Rrole[0].Speed := 25 + random(6);
        Rrole[0].Defence := 25 + random(6);
        Rrole[0].Medcine := 25 + random(6);
        Rrole[0].UsePoi := 25 + random(6);
        Rrole[0].MedPoi := 25 + random(6);
        Rrole[0].Fist := 25 + random(6);
        Rrole[0].Sword := 25 + random(6);
        Rrole[0].Knife := 25 + random(6);
        Rrole[0].Unusual := 25 + random(6);
        Rrole[0].HidWeapon := 25 + random(6);

      end;

      Rrole[0].Aptitude := 1 + random(100);

      if MODVersion = 0 then
      begin
        Rrole[0].Magic[0] := 1;
        if random(100) < 70 then
          Rrole[0].Magic[0] := random(93);
      end;
      if MODVersion = 31 then
        Rrole[0].Ethics := random(50) + random(50);

      if MODVersion = 41 then
      begin
        Rrole[0].Magic[0] := 0;
      end;

      Redraw;
      ShowStatus(0);
      DrawShadowText(screen, str, CENTER_X - 273 + 10, CENTER_Y + 111, ColColor($21), ColColor($23));
      str0 := format('%4d', [Rrole[0].Aptitude]);
      DrawEngShadowText(screen, str0, CENTER_X - 273 + 110, CENTER_Y + 111, ColColor($64), ColColor($66));
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := WaitAnyKey;
    until (i = SDLK_ESCAPE) or (i = SDLK_RETURN);

    if MODVersion = 0 then
    begin
      if input_name = 'TXDX尊使' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;
        Rrole[0].Magic[0] := 62;
        Rrole[0].MagLevel[0] := 800;

        Rmagic[62].Attack[9] := 2000;

        Ritem[93].Magic := 26;
        Ritem[66].OnlyPracRole := -1;
        Ritem[79].OnlyPracRole := -1;

        instruct_32(82, 1);
        instruct_32(74, 1);

      end;
      Rrole[13].Magic[1] := 91;
    end;

    if MODVersion = 22 then
    begin
      if input_name = 'k小邪' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 150;
        Rrole[0].Speed := 150;
        Rrole[0].Defence := 130;
        Rrole[0].Medcine := 130;
        Rrole[0].UsePoi := 130;
        Rrole[0].MedPoi := 130;
        Rrole[0].Fist := 130;
        Rrole[0].Sword := 130;
        Rrole[0].Knife := 130;
        Rrole[0].Unusual := 130;
        Rrole[0].HidWeapon := 130;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 85;

        Rrole[0].Magic[0] := 94;
        Rrole[0].MagLevel[0] := 850;
        Rrole[0].Magic[1] := 93;

        Rrole[0].AttPoi := 0;
      end;

      if input_name = '龍吟星落' then
      begin
        Rrole[0].MaxHP := 150;
        Rrole[0].CurrentHP := 120;
        Rrole[0].MaxMP := 150;
        Rrole[0].CurrentMP := 220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 130;
        Rrole[0].Speed := 130;
        Rrole[0].Defence := 130;
        Rrole[0].Medcine := 130;
        Rrole[0].UsePoi := 130;
        Rrole[0].MedPoi := 130;
        Rrole[0].Fist := 130;
        Rrole[0].Sword := 130;
        Rrole[0].Knife := 130;
        Rrole[0].Unusual := 130;
        Rrole[0].HidWeapon := 130;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 168;
        Rrole[0].Magic[1] := 169;
        Rrole[0].Magic[2] := 170;
        Rrole[0].Magic[3] := 171;
        Rrole[0].Magic[4] := 172;
      end;

      if input_name = '小隨' then
      begin
        Rrole[0].MaxHP := 150;
        Rrole[0].CurrentHP := 120;
        Rrole[0].MaxMP := 150;
        Rrole[0].CurrentMP := 220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 130;
        Rrole[0].Speed := 130;
        Rrole[0].Defence := 130;
        Rrole[0].Medcine := 130;
        Rrole[0].UsePoi := 130;
        Rrole[0].MedPoi := 130;
        Rrole[0].Fist := 130;
        Rrole[0].Sword := 130;
        Rrole[0].Knife := 130;
        Rrole[0].Unusual := 130;
        Rrole[0].HidWeapon := 130;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 94;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttTwice := 1;
      end;

      if input_name = '破大俠' then
      begin
        Rrole[0].MaxHP := 1150;
        Rrole[0].CurrentHP := 1120;
        Rrole[0].MaxMP := 1150;
        Rrole[0].CurrentMP := 1220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 230;
        Rrole[0].Speed := 230;
        Rrole[0].Defence := 230;
        Rrole[0].Medcine := 230;
        Rrole[0].UsePoi := 230;
        Rrole[0].MedPoi := 230;
        Rrole[0].Fist := 230;
        Rrole[0].Sword := 230;
        Rrole[0].Knife := 230;
        Rrole[0].Unusual := 230;
        Rrole[0].HidWeapon := 230;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 100;

        Rrole[0].Magic[0] := 168;
        Rrole[0].Magic[1] := 169;
        Rrole[0].Magic[2] := 170;
        Rrole[0].Magic[3] := 171;
        Rrole[0].Magic[4] := 172;
        Rrole[0].Magic[5] := 94;

        //rrole[0].AttTwice := 1;
      end;

      if input_name = '鳳凰' then
      begin
        Rrole[0].MaxHP := 250;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 250;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;
        Rrole[0].Aptitude := 100;
        for i := 1 to 14 do
        begin
          Rrole[i].MaxHP := 500;
          Rrole[i].CurrentHP := 500;
          Rrole[i].MaxMP := 500;
          Rrole[i].CurrentMP := 500;
          Rrole[i].MPType := 2;
          Rrole[i].IncLife := 30;

          Rrole[i].Attack := 300;
          Rrole[i].Speed := 100;
          Rrole[i].Defence := 130;
          Rrole[i].Medcine := 130;
          Rrole[i].UsePoi := 130;
          Rrole[i].MedPoi := 130;
          Rrole[i].Fist := 130;
          Rrole[i].Sword := 130;
          Rrole[i].Knife := 130;
          Rrole[i].Unusual := 130;
          Rrole[i].HidWeapon := 130;

          Rrole[i].Aptitude := 100;
        end;
      end;
    end;

    if MODVersion = 23 then
    begin
      if input_name = '小小豬' then
      begin
        Rrole[0].MaxHP := 10;
        Rrole[0].CurrentHP := 10;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 10;
        Rrole[0].Speed := 10;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 27;
        Rrole[0].MagLevel[0] := 850;
        Rrole[0].Magic[1] := 37;
        Rrole[0].MagLevel[1] := 850;
        Rrole[0].Magic[2] := 94;
        Rrole[0].MagLevel[2] := 850;
        Rrole[0].Magic[3] := 62;
        Rrole[0].MagLevel[3] := 850;

        Rrole[0].AttPoi := 0;
      end;

      if input_name = 'k小邪' then
      begin
        Rrole[0].MaxHP := 150;
        Rrole[0].CurrentHP := 120;
        Rrole[0].MaxMP := 150;
        Rrole[0].CurrentMP := 220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 27;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttPoi := 70;

        Rrole[0].Magic[1] := 15;

        for i := 0 to 9 do
        begin
          Rmagic[15].Attack[i] := 1400;
          Rmagic[16].Attack[i] := 1400;
          Rmagic[17].Attack[i] := 1000;
          Rmagic[15].AttDistance[i] := 6;
          Rmagic[16].AttDistance[i] := 4;
          Rmagic[17].AttDistance[i] := 8;
        end;
      end;

      if input_name = '南宮夢' then
      begin
        Rrole[0].MaxHP := 500;
        Rrole[0].CurrentHP := 500;
        Rrole[0].MaxMP := 500;
        Rrole[0].CurrentMP := 500;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 70;
        Rrole[0].Speed := 90;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 60;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 37;
        Rrole[0].MagLevel[0] := 890;

        Rmagic[37].AttAreaType := 3;
        Rmagic[37].MoveDistance[9] := 4;
        Rmagic[37].AttDistance[9] := 4;
      end;

      if input_name = '游客' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 94;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttTwice := 1;
      end;

      if input_name = '飛蟲王' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 60;

        Rrole[0].Magic[0] := 62;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttPoi := 95;
      end;

      if input_name = '破劍式' then
      begin
        Rrole[0].MaxHP := 499;
        Rrole[0].CurrentHP := 499;
        Rrole[0].MaxMP := 499;
        Rrole[0].CurrentMP := 499;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 5;

        Rrole[0].Attack := 90;
        Rrole[0].Speed := 90;
        Rrole[0].Defence := 90;
        Rrole[0].Medcine := 90;
        Rrole[0].UsePoi := 90;
        Rrole[0].MedPoi := 90;
        Rrole[0].Fist := 90;
        Rrole[0].Sword := 90;
        Rrole[0].Knife := 90;
        Rrole[0].Unusual := 90;
        Rrole[0].HidWeapon := 90;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 27;
        Rrole[0].MagLevel[0] := 899;
        Rrole[0].Magic[1] := 37;
        Rrole[0].MagLevel[1] := 899;
        Rrole[0].Magic[2] := 94;
        Rrole[0].MagLevel[2] := 899;
        Rrole[0].Magic[3] := 62;
        Rrole[0].MagLevel[3] := 899;

        Rrole[0].AttPoi := 90;
      end;

      if input_name = '9523' then
      begin
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 10;
        Rrole[0].Speed := 10;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        for i := 0 to 9 do
        begin
          Rmagic[15].Attack[i] := 1400;
          Rmagic[16].Attack[i] := 1400;
          Rmagic[17].Attack[i] := 1000;
          Rmagic[15].AttDistance[i] := 6;
          Rmagic[16].AttDistance[i] := 4;
          Rmagic[17].AttDistance[i] := 8;
        end;

        Rrole[0].Magic[0] := 15;
        Rrole[0].Magic[1] := 16;
        Rrole[0].Magic[2] := 17;
      end;

      if input_name = '鳳凰ice' then
      begin
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;
        Rrole[0].Aptitude := 100;
        for i := 0 to 99 do
        begin
          if leavelist[i] > 0 then
          begin
            Rrole[leavelist[i]].IncLife := 30;
            Rrole[leavelist[i]].MPType := 2;
            Rrole[leavelist[i]].Attack := 90;
            Rrole[leavelist[i]].Aptitude := 95;
          end;
        end;
      end;
      Rrole[401] := Rrole[0];
      Rrole[402] := Rrole[0];
      Rrole[403] := Rrole[0];
      Rrole[404] := Rrole[0];
    end;

    if MODVersion = 11 then
    begin
      if input_name = '小小豬' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;
        Rrole[0].Ethics := 90;
        //rrole[0].Magic[0] := 62;
        //rrole[0].MagLevel[0] := 800;

        //rmagic[62].Attack[9] := 2000;

        //ritem[93].Magic := 26;
        //ritem[66].OnlyPracRole := -1;
        //ritem[79].OnlyPracRole := -1;

        //instruct_32(82, 1);
        //instruct_32(74, 1);

      end;

      if input_name = '晴空飛雪' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        //rrole[0].Magic[0] := 62;
        //rrole[0].MagLevel[0] := 800;

        //rmagic[62].Attack[9] := 2000;

        //ritem[93].Magic := 26;
        //ritem[66].OnlyPracRole := -1;
        //ritem[79].OnlyPracRole := -1;

        instruct_32(19, 10000);
        //instruct_32(74, 1);

      end;
    end;

    if MODVersion = 12 then
    begin
      if input_name = '小小豬' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;
      end;

      if input_name = '見賢思齊' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 60;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 60;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 45;
      end;
    end;

    if MODVersion = 31 then
    begin
      if input_name = '南宮夢' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 300;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 300;
        Rrole[0].Medcine := 300;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 300;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 300;

        Rrole[0].Aptitude := 100;
        Rrole[0].Ethics := 95;
      end;
    end;

    if MODVersion = 41 then
    begin
      if input_name = 'leo' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 30;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;
      end;
    end;

    if MODVersion = 21 then
    begin
      if (input_name = '古天奇') or (input_name = '青狼火花') then
      begin
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 20;
        Rrole[0].Aptitude := 100;
      end;
    end;

    ShowStatus(0);
    DrawShadowText(screen, str, 30, CENTER_Y + 111, ColColor($23), ColColor($21));
    str0 := format('%4d', [Rrole[0].Aptitude]);
    DrawEngShadowText(screen, str0, 150, CENTER_Y + 111, ColColor($66), ColColor($63));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

    StartAmi;
  end;
  //EndAmi;
  Result := named;

end;

//读入存档, 如为0则读入起始存档
procedure LoadR(num: integer);
var
  filename: utf8string;
  idx, grp, i1, i2, len: integer;
  BasicOffset, RoleOffset, ItemOffset, SceneOffset, MagicOffset, WeiShopOffset, i: integer;
begin
  SaveNum := num;
  filename := 'r' + IntToStr(num);

  if num = 0 then
    filename := 'ranger';
  idx := FileOpen(AppPath + 'save/ranger.idx', fmOpenRead);
  grp := FileOpen(AppPath + 'save/' + filename + '.grp', fmOpenRead);

  FileRead(idx, RoleOffset, 4);
  FileRead(idx, ItemOffset, 4);
  FileRead(idx, SceneOffset, 4);
  FileRead(idx, MagicOffset, 4);
  FileRead(idx, WeiShopOffset, 4);
  FileRead(idx, len, 4);
  FileSeek(grp, 0, 0);

  FileRead(grp, Inship, 2);
  FileRead(grp, UseLess1, 2);
  FileRead(grp, My, 2);
  FileRead(grp, Mx, 2);
  FileRead(grp, Sy, 2);
  FileRead(grp, Sx, 2);
  FileRead(grp, Mface, 2);
  FileRead(grp, shipx, 2);
  FileRead(grp, shipy, 2);
  FileRead(grp, shipx1, 2);
  FileRead(grp, shipy1, 2);
  FileRead(grp, shipface, 2);
  FileRead(grp, teamlist[0], 2 * 6);
  setlength(RItemlist, MAX_ITEM_AMOUNT);
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    RItemlist[i].Number := -1;
    RItemlist[i].Amount := 0;
  end;
  FileRead(grp, RItemlist[0], sizeof(Titemlist) * MAX_ITEM_AMOUNT);

  FileRead(grp, Rrole[0], ItemOffset - RoleOffset);
  FileRead(grp, Ritem[0], SceneOffset - ItemOffset);
  FileRead(grp, Rscene[0], MagicOffset - SceneOffset);
  FileRead(grp, Rmagic[0], WeiShopOffset - MagicOffset);
  FileRead(grp, Rshop[0], len - WeiShopOffset);
  FileClose(idx);
  FileClose(grp);

  //初始化入口
  SceneAmount := (MagicOffset - SceneOffset) div sizeof(TScene);
  for i := 0 to SceneAmount - 1 do
  begin
    if (Rscene[i].MainEntranceX1 >= 0) and (Rscene[i].MainEntranceX1 < 480) and (Rscene[i].MainEntranceY1 >= 0) and (Rscene[i].MainEntranceY1 < 480) then
      Entrance[Rscene[i].MainEntranceX1, Rscene[i].MainEntranceY1] := i;
    if (Rscene[i].MainEntranceX2 >= 0) and (Rscene[i].MainEntranceX2 < 480) and (Rscene[i].MainEntranceY2 >= 0) and (Rscene[i].MainEntranceY2 < 480) then
      Entrance[Rscene[i].MainEntranceX2, Rscene[i].MainEntranceY2] := i;
  end;
  //showmessage(inttostr(useless1));
  if UseLess1 > 0 then
  begin
    CurScene := UseLess1 - 1;
    where := 1;
  end
  else
  begin
    CurScene := -1;
    where := 0;
  end;

  filename := 's' + IntToStr(num);
  if num = 0 then
    filename := 'allsin';
  grp := FileOpen(AppPath + 'save/' + filename + '.grp', fmOpenRead);
  FileRead(grp, Sdata[0, 0, 0, 0], SceneAmount * 64 * 64 * 6 * 2);
  FileClose(grp);
  filename := 'd' + IntToStr(num);
  if num = 0 then
    filename := 'alldef';
  grp := FileOpen(AppPath + 'save/' + filename + '.grp', fmOpenRead);
  FileRead(grp, Ddata[0, 0, 0], SceneAmount * 200 * 11 * 2);
  FileClose(grp);

end;

//存档
procedure SaveR(num: integer);
var
  filename: utf8string;
  idx, grp, i1, i2, length, SceneAmount: integer;
  BasicOffset, RoleOffset, ItemOffset, SceneOffset, MagicOffset, WeiShopOffset, i: integer;
begin
  SaveNum := num;
  filename := 'r' + IntToStr(num);

  if num = 0 then
    filename := 'ranger';
  idx := FileOpen(AppPath + 'save/ranger.idx', fmOpenRead);
  grp := filecreate(AppPath + 'save/' + filename + '.grp', fmopenreadwrite);
  BasicOffset := 0;
  FileRead(idx, RoleOffset, 4);
  FileRead(idx, ItemOffset, 4);
  FileRead(idx, SceneOffset, 4);
  FileRead(idx, MagicOffset, 4);
  FileRead(idx, WeiShopOffset, 4);
  FileRead(idx, length, 4);
  FileSeek(grp, 0, 0);
  FileWrite(grp, Inship, 2);

  if where = 1 then
    UseLess1 := CurScene + 1
  else
    UseLess1 := 0;

  FileWrite(grp, UseLess1, 2);
  FileWrite(grp, My, 2);
  FileWrite(grp, Mx, 2);
  FileWrite(grp, Sy, 2);
  FileWrite(grp, Sx, 2);
  FileWrite(grp, Mface, 2);
  FileWrite(grp, shipx, 2);
  FileWrite(grp, shipy, 2);
  FileWrite(grp, shipx1, 2);
  FileWrite(grp, shipy1, 2);
  FileWrite(grp, shipface, 2);
  FileWrite(grp, teamlist[0], 2 * 6);
  FileWrite(grp, RItemlist[0], sizeof(Titemlist) * MAX_ITEM_AMOUNT);

  FileWrite(grp, Rrole[0], ItemOffset - RoleOffset);
  FileWrite(grp, Ritem[0], SceneOffset - ItemOffset);
  FileWrite(grp, Rscene[0], MagicOffset - SceneOffset);
  FileWrite(grp, Rmagic[0], WeiShopOffset - MagicOffset);
  FileWrite(grp, Rshop[0], length - WeiShopOffset);
  FileClose(idx);
  FileClose(grp);

  SceneAmount := (MagicOffset - SceneOffset) div sizeof(TScene);

  filename := 's' + IntToStr(num);
  if num = 0 then
    filename := 'allsin';
  grp := filecreate(AppPath + 'save/' + filename + '.grp');
  FileWrite(grp, Sdata[0, 0, 0, 0], SceneAmount * 64 * 64 * 6 * 2);
  FileClose(grp);
  filename := 'd' + IntToStr(num);
  if num = 0 then
    filename := 'alldef';
  grp := filecreate(AppPath + 'save/' + filename + '.grp');
  FileWrite(grp, Ddata[0, 0, 0], SceneAmount * 200 * 11 * 2);
  FileClose(grp);

end;

//等待任意按键
function WaitAnyKey: integer;
var
  x, y: integer;
begin
  //event.type_ := SDL_NOEVENT;
  //SDL_EventState(SDL_EVENT_KEY_DOWN, SDL_ENABLE);
  //SDL_EventState(SDL_EVENT_KEY_UP, SDL_ENABLE);
  //SDL_EventState(SDL_mousebuttonUP, SDL_ENABLE);
  //SDL_EventState(SDL_mousebuttonDOWN, SDL_ENABLE);
  event.key.key := 0;
  event.button.button := 0;
  while (SDL_PollEvent(@event) or True) do
  begin
    CheckBasicEvent;
    if (event.type_ = SDL_EVENT_KEY_UP) or (event.type_ = SDL_EVENT_MOUSE_BUTTON_UP) then
      if (event.key.key <> 0) or (event.button.button <> 0) then
        break;
    SDL_Delay(20);
  end;
  Result := event.key.key;
  if event.type_ = SDL_EVENT_MOUSE_BUTTON_UP then
  begin
    if event.button.button = SDL_BUTTON_LEFT then
    begin
      Result := SDLK_SPACE;
    end;
    if event.button.button = SDL_BUTTON_RIGHT then
      Result := SDLK_ESCAPE;
  end;
  event.key.key := 0;
  event.button.button := 0;
end;

//于主地图行走
procedure Walk;
var
  word: array [0 .. 10] of uint16;
  x, y, walking, Speed, Mx1, My1, Mx2, My2, i, i1, i2, stillcount, axp, ayp: integer;
  axp1, ayp1, gotoEntrance, minstep, step, drawed: integer;
  now, next_time, next_time2, next_time3: uint32;
  keystate: putf8char;
  pos: Tposition;
begin
  if where >= 3 then
    exit;
  next_time := SDL_GetTicks;
  next_time2 := SDL_GetTicks;
  next_time3 := SDL_GetTicks;

  Mx1 := 0;
  Mx2 := 0;

  where := 0;
  walking := 0;
  Speed := 0;
  DrawMMap;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //SDL_EnableKeyRepeat(50, 30);
  //StopMp3;
  //PlayMp3(16, -1);
  still := 0;
  stillcount := 0;

  //ExecScript('test.txt');
  //事件轮询(并非等待)
  while True do
  begin
    SDL_PollEvent(@event);
    //如果当前处于标题画面, 则退出, 用于战斗失败
    if where >= 3 then
    begin
      break;
    end;

    //主地图动态效果
    now := SDL_GetTicks;

    //闪烁效果
    if (integer(now - next_time2) > 0) {and (still =  1)} then
    begin
      ChangeCol;
      next_time2 := now + 200;
      //DrawMMap;
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //飘云
    if (integer(now - next_time3) > 0) and (MMAPAMI > 0) then
    begin
      for i := 0 to CLOUD_AMOUNT - 1 do
      begin
        Cloud[i].Positionx := Cloud[i].Positionx + Cloud[i].Speedx;
        Cloud[i].Positiony := Cloud[i].Positiony + Cloud[i].Speedy;
        if (Cloud[i].Positionx > 17279) or (Cloud[i].Positionx < 0) or (Cloud[i].Positiony > 8639) or (Cloud[i].Positiony < 0) then
        begin
          CloudCreateOnSide(i);
        end;
      end;
      next_time3 := now + 40;
      //DrawMMap;
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //主角动作
    if (integer(now - next_time) > 0) and (where = 0) then
    begin
      if (walking = 0) then
        stillcount := stillcount + 1
      else
        stillcount := 0;

      if stillcount >= 10 then
      begin
        still := 1;
        MStep := MStep + 1;
        if MStep > 6 then
          MStep := 1;
      end;
      next_time := now + 320;
    end;

    CheckBasicEvent;
    case event.type_ of
      //方向键使用压下按键事件, 按下方向设置状态为行走
      SDL_EVENT_KEY_DOWN:
      begin
        if (event.key.key = SDLK_LEFT) then
        begin
          Mface := 2;
          walking := 1;
        end;
        if (event.key.key = SDLK_RIGHT) then
        begin
          Mface := 1;
          walking := 1;
        end;
        if (event.key.key = SDLK_UP) then
        begin
          Mface := 0;
          walking := 1;
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          Mface := 3;
          walking := 1;
        end;
      end;
      //功能键(esc)使用松开按键事件
      SDL_EVENT_KEY_UP:
      begin
        keystate := putf8char(SDL_GetKeyboardState(nil));
        if (pbyte(keystate + SDL_scancode_LEFT)^ = 0) and (pbyte(keystate + SDL_scancode_RIGHT)^ = 0) and (pbyte(keystate + SDL_scancode_UP)^ = 0) and (pbyte(keystate + SDL_scancode_DOWN)^ = 0) then
        begin
          walking := 0;
          Speed := 0;
        end;
        //keystate := nil;
        {if event.key.key in [sdlk_left, sdlk_right, sdlk_up, sdlk_down] then
          begin
          walking := 0;
          end;}
        if (event.key.key = SDLK_ESCAPE) then
        begin
          //event.key.key:=0;
          MenuEsc;
          //walking := 0;
        end;
        {if (event.key.key = sdlk_return) and (event.key.key.modifier = kmod_lalt) then
          begin
          if fullscreen = 1 then
          screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, ScreenFlag)
          else
          screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
          fullscreen := 1 - fullscreen;
          end;}
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if ShowVirtualKey = 0 then
        begin
          SDL_GetMouseState2(x, y);
          if (x < CENTER_X) and (y < CENTER_Y) then
            Mface := 2;
          if (x > CENTER_X) and (y < CENTER_Y) then
            Mface := 0;
          if (x < CENTER_X) and (y > CENTER_Y) then
            Mface := 3;
          if (x > CENTER_X) and (y > CENTER_Y) then
            Mface := 1;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if event.button.button = SDL_BUTTON_RIGHT then
        begin
          event.button.button := 0;
          //showmessage(inttostr(walking));
          MenuEsc;
          nowstep := -1;
          walking := 0;
        end;
        if event.button.button = SDL_BUTTON_LEFT then
        begin
          walking := 2;
          GetMousePosition(axp, ayp, Mx, My);
          if (ayp >= 0) and (ayp <= 479) and (axp >= 0) and (axp <= 479) {and canWalk(axp, ayp)} then
          begin
            FillChar(Fway[0, 0], sizeof(Fway), -1);
            FindWay(Mx, My);
            gotoEntrance := -1;
            if (Buildy[axp, ayp] > 0) and (Entrance[axp, ayp] < 0) then
            begin
              //点到建筑在附近格内寻找入口
              axp := Buildx[axp, ayp];
              ayp := Buildy[axp, ayp];
              for i1 := axp - 3 to axp do
                for i2 := ayp - 3 to ayp do
                  if (i1 >= 0) and (i2 >= 0) and (Entrance[i1, i2] >= 0) and (Buildx[i1, i2] = axp) and (Buildy[i1, i2] = ayp) then
                  begin
                    axp := i1;
                    ayp := i2;
                    break;
                  end;
            end;
            if Entrance[axp, ayp] >= 0 then
            begin
              minstep := 4096;
              for i := 0 to 3 do
              begin
                axp1 := axp;
                ayp1 := ayp;
                case i of
                  0: axp1 := axp - 1;
                  1: ayp1 := ayp + 1;
                  2: ayp1 := ayp - 1;
                  3: axp1 := axp + 1;
                end;
                step := Fway[axp1, ayp1];
                if (step >= 0) and (minstep > step) then
                begin
                  gotoEntrance := i;
                  minstep := step;
                end;
              end;
              if gotoEntrance >= 0 then
              begin
                case gotoEntrance of
                  0: axp := axp - 1;
                  1: ayp := ayp + 1;
                  2: ayp := ayp - 1;
                  3: axp := axp + 1;
                end;
                gotoEntrance := 3 - gotoEntrance;
              end;
            end;
            FindWay(Mx, My);
            Moveman(Mx, My, axp, ayp);
            nowstep := Fway[axp, ayp] - 1;
          end
          else
          begin
            walking := 0;
          end;
        end;
      end;
    end;

    //如果主角正在行走, 则移动主角
    if walking > 0 then
    begin
      still := 0;
      stillcount := 0;
      case walking of
        1:
        begin
          Speed := Speed + 1;
          Mx1 := Mx;
          My1 := My;
          if (Speed = 1) or (Speed >= 5) then
          begin
            case Mface of
              0: Mx1 := Mx1 - 1;
              1: My1 := My1 + 1;
              2: My1 := My1 - 1;
              3: Mx1 := Mx1 + 1;
            end;
            MStep := MStep + 1;
            if MStep >= 7 then
              MStep := 1;
            if CanWalk(Mx1, My1) = True then
            begin
              Mx := Mx1;
              My := My1;
            end;
          end;
        end;
        2:
        begin
          if nowstep < 0 then
          begin
            walking := 0;
            if gotoEntrance >= 0 then
            begin
              Mface := gotoEntrance;
              //CheckEntrance;
            end;
          end
          else
          begin
            still := 0;
            if sign(linex[nowstep] - Mx) < 0 then
              Mface := 0
            else if sign(linex[nowstep] - Mx) > 0 then
              Mface := 3
            else if sign(liney[nowstep] - My) > 0 then
              Mface := 1
            else
              Mface := 2;

            MStep := MStep + 1;

            if MStep >= 7 then
              MStep := 1;
            if (abs(Mx - linex[nowstep]) + abs(My - liney[nowstep]) = 1) and CanWalk(linex[nowstep], liney[nowstep]) then
            begin
              Mx := linex[nowstep];
              My := liney[nowstep];
            end
            else
              walking := 0;

            Dec(nowstep);
          end;
        end;
      end;

      //每走一步均重画屏幕, 并检测是否处于某场景入口
      Redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      if CheckEntrance then
      begin
        walking := 0;
        MStep := 0;
        still := 0;
        stillcount := 0;
        Speed := 0;
        if MMAPAMI = 0 then
        begin
          Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;

      //SDL_Delay(WALK_SPEED);
    end;

    if where = 1 then
    begin
      WalkInScene(0);
    end;

    event.key.key := 0;
    event.button.button := 0;
    //走路时不重复画了
    if walking = 0 then
    begin
      if MMAPAMI > 0 then
      begin
        Redraw;
        GetMousePosition(axp, ayp, Mx, My);
        pos := GetPositionOnScreen(axp, ayp, Mx, My);
        DrawMPic(1, pos.x, pos.y, 0, 50, 0, 0);
        {if not CanWalk(axp, ayp) then
          begin
          if Entrance[axp, ayp] >= 0 then
          DrawMPic(2001, pos.x, pos.y, 0, 75, 0, 0)
          else
          DrawMPic(2001, pos.x, pos.y, 0, 50, 0, 0);
          end;}
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_Delay(40); //静止时只需刷新率与最频繁的动态效果相同即可
    end
    else
      SDL_Delay(WALK_SPEED);
  end;

  //SDL_EnableKeyRepeat(0, 10);

end;

//判定主地图某个位置能否行走, 是否变成船
function CanWalk(x, y: integer): boolean;
begin
  if Buildx[x, y] = 0 then
    CanWalk := True
  else
    CanWalk := False;
  //canwalk:=true;  //This sentence is used to test.
  if (x <= 0) or (x >= 479) or (y <= 0) or (y >= 479) then
    CanWalk := False;
  if (Earth[x, y] = 838) or ((Earth[x, y] >= 612) and (Earth[x, y] <= 670)) then
    CanWalk := False;
  if ((Earth[x, y] >= 358) and (Earth[x, y] <= 362)) or ((Earth[x, y] >= 506) and (Earth[x, y] <= 670)) or ((Earth[x, y] >= 1016) and (Earth[x, y] <= 1022)) then
    Inship := 1
  else
    Inship := 0;

  if MODVersion = 22 then
  begin
    if Inship = 1 then
    begin
      CanWalk := False;
      Inship := 0;
    end;
  end;

end;

//Check able or not to ertrance a scene.
//检测是否处于某入口, 并是否达成进入条件
function CheckEntrance: boolean;
var
  x, y, i, snum: integer;
  //CanEntrance: boolean;
begin
  x := Mx;
  y := My;
  case Mface of
    0: x := x - 1;
    1: y := y + 1;
    2: y := y - 1;
    3: x := x + 1;
  end;
  Result := False;
  if (Entrance[x, y] >= 0) then
  begin
    Result := False;
    snum := Entrance[x, y];
    if (Rscene[snum].EnCondition = 0) then
      Result := True;
    //是否有人轻功超过70
    if (Rscene[snum].EnCondition = 2) then
      for i := 0 to 5 do
        if teamlist[i] >= 0 then
          if Rrole[teamlist[i]].Speed > 70 then
            Result := True;
    if Result = True then
    begin
      instruct_14;
      CurScene := Entrance[x, y];
      SFace := Mface;
      Mface := 3 - Mface;
      SStep := 0;
      Sx := Rscene[CurScene].EntranceX;
      Sy := Rscene[CurScene].EntranceY;
      //如达成条件, 进入场景并初始化场景坐标
      SaveR(11);
      WalkInScene(0);
      event.key.key := 0;
      event.button.button := 0;
      //waitanykey;
    end;
    //instruct_13;
  end;
  //result:=canentrance;

end;

function UpdateSceneAmi(param: pointer; timerid: TSDL_TimerID; interval: uint32): uint32;
begin
  Result := 200;
  //while True do
  begin
    if (where = 1) and (CurEvent < 0) and (not LoadingScene) and (NeedRefreshScene <> 0) then
      InitialScene(2);
    //if (where < 1) or (where > 2) then
    //break;
  end;

end;

//Walk in a scene, the returned value is the scene number when you exit. If it is -1.
//WalkInScene(1) means the new game.
//在内场景行走, 如参数为1表示新游戏
function WalkInScene(Open: integer): integer;
var
  grp, idx, offset, just, i1, i2, x, y, haveAmi, preface, drawed: integer;
  Sx1, Sy1, s, i, walking, Prescene, stillcount, Speed, axp, ayp, gotoevent, minstep, axp1, ayp1, step: integer;
  filename: utf8string;
  scenename: utf8string;
  now, next_time, next_time2: uint32;
  AmiCount: integer; //场景内动态效果计数
  keystate: putf8char;
  UpDate: PSDL_Thread;
  pos: Tposition;
begin

  //LockScene := false;
  next_time := SDL_GetTicks;

  where := 1;
  walking := 0; //为0表示静止, 为1表示键盘行走, 为2表示鼠标行走
  just := 0;
  CurEvent := -1;
  AmiCount := 0;
  Speed := 0;
  stillcount := 0;

  exitscenemusicnum := Rscene[CurScene].ExitMusic;

  //SDL_EnableKeyRepeat(50, 30);

  InitialScene;

  for i := 0 to 199 do
    if (Ddata[CurScene, i, 7] < Ddata[CurScene, i, 6]) then
    begin
      Ddata[CurScene, i, 5] := Ddata[CurScene, i, 7] + Ddata[CurScene, i, 8] * 2 mod (Ddata[CurScene, i, 6] - Ddata[CurScene, i, 7] + 2);
    end;

  if Open = 1 then
  begin
    Sx := BEGIN_Sx;
    Sy := BEGIN_Sy;
    Cx := Sx;
    Cy := Sy;
    CurSceneRolePic := 3445;
    CurEvent := BEGIN_EVENT;
    CallEvent(BEGIN_EVENT);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    CurEvent := -1;
  end;

  SStep := 0;

  DrawScene;
  ShowSceneName(CurScene);
  //是否有第3类事件位于场景入口
  CheckEvent3;

  //if SCENEAMI = 2 then
  //UpDate := SDL_CreateThread(@UpdateSceneAmi, nil, nil);
  while (SDL_PollEvent(@event)) or True do
  begin
    if where <> 1 then
    begin
      break;
    end;
    if Sx > 63 then
      Sx := 63;
    if Sy > 63 then
      Sy := 63;
    if Sx < 0 then
      Sx := 0;
    if Sy < 0 then
      Sy := 0;
    //场景内动态效果
    now := SDL_GetTicks;
    //next_time:=sdl_getticks;
    if integer(now - next_time) > 0 then
    begin
      haveAmi := 0;
      for i := 0 to 199 do
        if (Ddata[CurScene, i, 7] < Ddata[CurScene, i, 6]) {and (AmiCount > (DData[CurScene, i, 8] + 1))} then
        begin
          Ddata[CurScene, i, 5] := Ddata[CurScene, i, 5] + 2;
          if Ddata[CurScene, i, 5] > Ddata[CurScene, i, 6] then
            Ddata[CurScene, i, 5] := Ddata[CurScene, i, 7];
          haveAmi := haveAmi + 1;
        end;
      //if we never consider the change of color panel, there is no need to re-initial scene.
      //if (haveAmi > 0) then
      //if not (IsCave(CurScene)) then
      if SCENEAMI = 1 then
      begin
        InitialScene(1);
      end;

      if walking = 0 then
        stillcount := stillcount + 1
      else
        stillcount := 0;
      if stillcount >= 20 then
      begin
        SStep := 0;
        stillcount := 0;
      end;

      next_time := now + 200;
      AmiCount := AmiCount + 1;
      ChangeCol;
      //DrawScene;
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //检查是否位于出口, 如是则退出
    if (((Sx = Rscene[CurScene].ExitX[0]) and (Sy = Rscene[CurScene].ExitY[0])) or ((Sx = Rscene[CurScene].ExitX[1]) and (Sy = Rscene[CurScene].ExitY[1])) or ((Sx = Rscene[CurScene].ExitX[2]) and (Sy = Rscene[CurScene].ExitY[2]))) then
    begin
      where := 0;
      Result := -1;
      break;
    end;
    //检查是否位于跳转口, 如是则重新初始化场景
    //如果处于站立状态则不跳转, 防止连续跳转
    if ((Sx = Rscene[CurScene].JumpX1) and (Sy = Rscene[CurScene].JumpY1)) and (Rscene[CurScene].JumpScene >= 0) {and (SStep <> 0)} then
    begin
      instruct_14;
      Prescene := CurScene;
      CurScene := Rscene[CurScene].JumpScene;
      if Rscene[Prescene].MainEntranceX1 <> 0 then
      begin
        Sx := Rscene[CurScene].EntranceX;
        Sy := Rscene[CurScene].EntranceY;
      end
      else
      begin
        Sx := Rscene[CurScene].JumpX2;
        Sy := Rscene[CurScene].JumpY2;
      end;
      {if Sx = 0 then
        begin
        Sx := RScene[CurScene].JumpX2;
        Sy := RScene[CurScene].JumpY2;
        end;
        if Sx = 0 then
        begin
        Sx := RScene[CurScene].EntranceX;
        Sy := RScene[CurScene].EntranceY;
        end;}

      InitialScene;
      walking := 0;
      speed := 0;
      SStep := 0;
      DrawScene;
      ShowSceneName(CurScene);
      CheckEvent3;

    end;

    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        keystate := putf8char(SDL_GetKeyboardState(nil));
        if (pbyte(keystate + SDL_scancode_LEFT)^ = 0) and (pbyte(keystate + SDL_scancode_RIGHT)^ = 0) and (pbyte(keystate + SDL_scancode_UP)^ = 0) and (pbyte(keystate + SDL_scancode_DOWN)^ = 0) then
        begin
          walking := 0;
          Speed := 0;
        end;
        //keystate := nil;
        if (event.key.key = SDLK_ESCAPE) then
        begin
          MenuEsc;
          walking := 0;
          Speed := 0;
          //mousewalking := 0;
        end;
        //按下回车或空格, 检查面对方向是否有第1类事件
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          CheckEvent1;
        end;
      end;
      SDL_EVENT_KEY_DOWN:
      begin
        if (event.key.key = SDLK_LEFT) then
        begin
          SFace := 2;
          walking := 1;
        end;
        if (event.key.key = SDLK_RIGHT) then
        begin
          SFace := 1;
          walking := 1;
        end;
        if (event.key.key = SDLK_UP) then
        begin
          SFace := 0;
          walking := 1;
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          SFace := 3;
          walking := 1;
        end;
      end;
      {Sdl_mousebuttondown:
        begin
        if event.button.button = sdl_button_left then
        begin
        walking := 2;
        end;
        end;
        Sdl_mousebuttonup:
        begin
        if event.button.button = sdl_button_right then
        menuesc;
        if event.button.button = sdl_button_left then
        begin
        walking := 0;
        end;
        if event.button.button = sdl_button_middle then
        CheckEvent1;
        end;}
      SDL_EVENT_MOUSE_MOTION:
      begin
        if ShowVirtualKey = 0 then
        begin
          SDL_GetMouseState2(x, y);
          if (x < CENTER_X) and (y < CENTER_Y) then
            Mface := 2;
          if (x > CENTER_X) and (y < CENTER_Y) then
            Mface := 0;
          if (x < CENTER_X) and (y > CENTER_Y) then
            Mface := 3;
          if (x > CENTER_X) and (y > CENTER_Y) then
            Mface := 1;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if event.button.button = SDL_BUTTON_RIGHT then
        begin
          MenuEsc;
          nowstep := 0;
          walking := 0;
          Speed := 0;
          if where = 0 then
          begin
            if (CurScene >= 0) and (Rscene[CurScene].ExitMusic >= 0) then
            begin
              StopMP3;
              PlayMP3(Rscene[CurScene].ExitMusic, -1);
            end;
            Redraw;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            exit;
          end;
        end;
        if event.button.button = SDL_BUTTON_MIDDLE then
        begin
          CheckEvent1;
        end;
        if event.button.button = SDL_BUTTON_LEFT then
        begin
          if walking = 0 then
          begin
            walking := 2;
            GetMousePosition(axp, ayp, Sx, Sy, Sdata[CurScene, 4, Sx, Sy]);
            if (ayp in [0 .. 63]) and (axp in [0 .. 63]) then
            begin
              FillChar(Fway[0, 0], sizeof(Fway), -1);
              FindWay(Sx, Sy);
              gotoevent := -1;
              if (Sdata[CurScene, 3, axp, ayp] >= 0) then
              begin
                if abs(axp - Sx) + abs(ayp - Sy) = 1 then
                begin
                  if axp < Sx then
                    SFace := 0;
                  if axp > Sx then
                    SFace := 3;
                  if ayp < Sy then
                    SFace := 2;
                  if ayp > Sy then
                    SFace := 1;
                  if CheckEvent1 then
                    walking := 0;
                end
                else
                begin
                  if (not CanWalkInScene(axp, ayp)) then
                  begin
                    minstep := 4096;
                    for i := 0 to 3 do
                    begin
                      axp1 := axp;
                      ayp1 := ayp;
                      case i of
                        0: axp1 := axp - 1;
                        1: ayp1 := ayp + 1;
                        2: ayp1 := ayp - 1;
                        3: axp1 := axp + 1;
                      end;
                      step := Fway[axp1, ayp1];
                      if (step >= 0) and (minstep > step) then
                      begin
                        gotoevent := i;
                        minstep := step;
                      end;
                    end;
                    if gotoevent >= 0 then
                    begin
                      case gotoevent of
                        0: axp := axp - 1;
                        1: ayp := ayp + 1;
                        2: ayp := ayp - 1;
                        3: axp := axp + 1;
                      end;
                      gotoevent := 3 - gotoevent;
                    end;
                  end;
                end;
              end;
              Moveman(Sx, Sy, axp, ayp);
              nowstep := Fway[axp, ayp] - 1;
            end
            else
            begin
              walking := 0;
            end;
          end
          else
            walking := 0;
          event.button.button := 0;
        end;
      end;
    end;

    //是否处于行走状态
    if walking > 0 then
    begin
      case walking of
        1:
        begin
          Speed := Speed + 1;
          stillcount := 0;
          if (Speed = 1) or (Speed >= 5) then
          begin
            Sx1 := Sx;
            Sy1 := Sy;
            case SFace of
              0: Sx1 := Sx1 - 1;
              1: Sy1 := Sy1 + 1;
              2: Sy1 := Sy1 - 1;
              3: Sx1 := Sx1 + 1;
            end;
            SStep := SStep + 1;
            if SStep >= 7 then
              SStep := 1;
            if CanWalkInScene(Sx1, Sy1) = True then
            begin
              Sx := Sx1;
              Sy := Sy1;
            end;
          end;
        end;
        2:
        begin
          if nowstep >= 0 then
          begin
            if sign(liney[nowstep] - Sy) < 0 then
              SFace := 2
            else if sign(liney[nowstep] - Sy) > 0 then
              SFace := 1
            else if sign(linex[nowstep] - Sx) > 0 then
              SFace := 3
            else
              SFace := 0;

            SStep := SStep + 1;

            if SStep >= 7 then
              SStep := 1;
            if abs(Sx - linex[nowstep]) + abs(Sy - liney[nowstep]) = 1 then
            begin
              Sx := linex[nowstep];
              Sy := liney[nowstep];
            end
            else
              walking := 0;
            Dec(nowstep);
          end
          else
          begin
            walking := 0;
            if gotoevent >= 0 then
            begin
              SFace := gotoevent;
              Redraw;
              CheckEvent1;
            end;
          end;
        end;
      end;
      Redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      CheckEvent3;
      //SDL_Delay(WALK_SPEED2);
    end;

    event.key.key := 0;
    event.button.button := 0;

    if walking or Speed = 0 then
    begin
      if SCENEAMI > 0 then
      begin
        Redraw;
        if walking = 0 then
        begin
          GetMousePosition(axp, ayp, Sx, Sy, Sdata[CurScene, 4, Sx, Sy]);
          if (axp >= 0) and (axp < 64) and (ayp >= 0) and (ayp < 64) then
          begin
            pos := GetPositionOnScreen(axp, ayp, Sx, Sy);
            DrawMPic(1, pos.x, pos.y - Sdata[CurScene, 4, axp, ayp], 0, 50, 0, 0);
            //DrawMPic(1, pos.x, pos.y);
            {if not CanWalkInScene(axp, ayp) then
              begin
              if SData[CurScene, 3, axp, ayp] >= 0 then
              DrawMPic(2001, pos.x, pos.y - SData[CurScene, 4, axp, ayp], 0, 75, 0, 0)
              else
              DrawMPic(2001, pos.x, pos.y - SData[CurScene, 4, axp, ayp], 0, 50, 0, 0);
              end;}
          end;
        end;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_Delay(40);
    end
    else
    begin
      SDL_Delay(WALK_SPEED2);
    end;

  end;

  instruct_14; //黑屏

  //ReDraw;
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //if SCENEAMI = 2 then
  //SDL_KillThread(UpDate);
  if exitscenemusicnum > 0 then
  begin
    StopMP3;
    PlayMP3(exitscenemusicnum, -1);
  end;

end;

procedure FindWay(x1, y1: integer);
var
  Xlist: array [0 .. 4096] of smallint;
  Ylist: array [0 .. 4096] of smallint;
  steplist: array [0 .. 4096] of smallint;
  curgrid, totalgrid: integer;
  Bgrid: array [1 .. 4] of integer; //0空位, 1可过, 2已走过 ,3越界
  Xinc, Yinc: array [1 .. 4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, i3: integer;
  CanWalk: boolean;
begin
  Xinc[1] := 0;
  Xinc[2] := 1;
  Xinc[3] := -1;
  Xinc[4] := 0;
  Yinc[1] := -1;
  Yinc[2] := 0;
  Yinc[3] := 0;
  Yinc[4] := 1;
  curgrid := 0;
  totalgrid := 1;
  Xlist[0] := x1;
  Ylist[0] := y1;
  steplist[0] := 0;
  Fway[x1, y1] := 0;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];
    curstep := steplist[curgrid];
    //判断当前点四周格子的状况
    case where of
      1:
      begin
        for i := 1 to 4 do
        begin
          nextX := curX + Xinc[i];
          nextY := curY + Yinc[i];
          if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
            Bgrid[i] := 3//越界
          else if Fway[nextX, nextY] >= 0 then
            Bgrid[i] := 2//已走过
          else if not CanWalkInScene(curX, curY, nextX, nextY) then
            Bgrid[i] := 1//阻碍
          else
            Bgrid[i] := 0;
        end;
      end;
      0:
      begin
        for i := 1 to 4 do
        begin
          nextX := curX + Xinc[i];
          nextY := curY + Yinc[i];
          if (nextX < 0) or (nextX > 479) or (nextY < 0) or (nextY > 479) then
            Bgrid[i] := 3//越界
          else if (Entrance[nextX, nextY] >= 0) then
            Bgrid[i] := 6//入口
          else if Fway[nextX, nextY] >= 0 then
            Bgrid[i] := 2//已走过
          else if Buildx[nextX, nextY] > 0 then
            Bgrid[i] := 1//阻碍
          else if ((surface[nextX, nextY] >= 1692) and (surface[nextX, nextY] <= 1700)) then
            Bgrid[i] := 1
          else if (Earth[nextX, nextY] = 838) or ((Earth[nextX, nextY] >= 612) and (Earth[nextX, nextY] <= 670)) then
            Bgrid[i] := 1
          else if ((Earth[nextX, nextY] >= 358) and (Earth[nextX, nextY] <= 362)) or ((Earth[nextX, nextY] >= 506) and (Earth[nextX, nextY] <= 670)) or ((Earth[nextX, nextY] >= 1016) and (Earth[nextX, nextY] <= 1022)) then
          begin
            if (nextX = shipy) and (nextY = shipx) then
              Bgrid[i] := 4//船
            else if ((surface[nextX, nextY] div 2 >= 863) and (surface[nextX, nextY] div 2 <= 872)) or ((surface[nextX, nextY] div 2 >= 852) and (surface[nextX, nextY] div 2 <= 854)) or ((surface[nextX, nextY] div 2 >= 858) and (surface[nextX, nextY] div 2 <= 860)) then
              Bgrid[i] := 0//船
            else
              Bgrid[i] := 5; //水
          end
          else
            Bgrid[i] := 0;
        end;
      end;
      //移动的情况
    end;
    for i := 1 to 4 do
    begin
      CanWalk := False;
      case MODVersion of
        22:
        begin
          if ((Inship = 1) and (Bgrid[i] = 5)) or (((Bgrid[i] = 0) or (Bgrid[i] = 4)) and (Inship = 0)) then
            CanWalk := True;
        end;
        else
        begin
          if (Bgrid[i] = 0) or (Bgrid[i] = 4) or (Bgrid[i] = 5) or (Bgrid[i] = 7) then
            CanWalk := True;
        end;
      end;
      if CanWalk then
      begin
        Xlist[totalgrid] := curX + Xinc[i];
        Ylist[totalgrid] := curY + Yinc[i];
        steplist[totalgrid] := curstep + 1;
        Fway[Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
        totalgrid := totalgrid + 1;
        if totalgrid > 4096 then
          exit;
      end;
    end;
    curgrid := curgrid + 1;
    if (where = 0) and (curX - Mx > 22) and (curY - My > 22) then
      break;
  end;

end;

procedure Moveman(x1, y1, x2, y2: integer);
var
  s, i, i1, i2, a, tempx, tx1, tx2, ty1, ty2, tempy: integer;
  Xinc, Yinc, dir: array [1 .. 4] of integer;
begin
  if Fway[x2, y2] > 0 then
  begin
    Xinc[1] := 0;
    Xinc[2] := 1;
    Xinc[3] := -1;
    Xinc[4] := 0;
    Yinc[1] := -1;
    Yinc[2] := 0;
    Yinc[3] := 0;
    Yinc[4] := 1;
    linex[0] := x2;
    liney[0] := y2;
    for a := 1 to Fway[x2, y2] do
    begin
      for i := 1 to 4 do
      begin
        tempx := linex[a - 1] + Xinc[i];
        tempy := liney[a - 1] + Yinc[i];
        if (tempx >= 0) and (tempy >= 0) and (Fway[tempx, tempy] = Fway[linex[a - 1], liney[a - 1]] - 1) then
        begin
          linex[a] := tempx;
          liney[a] := tempy;
          break;
        end;
      end;
    end;
  end;
end;

procedure ShowSceneName(snum: integer);
var
  scenename: utf8string;
begin
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //显示场景名
  if snum >= 0 then
  begin
    scenename := cp950toutf8(@Rscene[snum].Name);
    DrawTextWithRect(screen, scenename, CENTER_X - length(putf8char(@Rscene[snum].Name)) * 5 + 7, 100, length(putf8char(@Rscene[snum].Name)) * 10 + 6, ColColor(5), ColColor(7));

    //改变音乐
    if Rscene[snum].EntranceMusic >= 0 then
    begin
      StopMP3;
      PlayMP3(Rscene[snum].EntranceMusic, -1);
    end;
  end;
  SDL_Delay(500);

end;

//判定场景内某个位置能否行走
function CanWalkInScene(x, y: integer): boolean; overload;
begin
  if (CurScene < 0) or (x < 0) or (y < 0) then
  begin
    Result := False;
    exit;
  end;
  if (Sdata[CurScene, 1, x, y] = 0) then
    Result := True
  else
    Result := False;
  if (Sdata[CurScene, 3, x, y] >= 0) and (Result) and (Ddata[CurScene, Sdata[CurScene, 3, x, y], 0] = 1) then
    Result := False;
  //直接判定贴图范围
  if ((Sdata[CurScene, 0, x, y] >= 358) and (Sdata[CurScene, 0, x, y] <= 362)) or (Sdata[CurScene, 0, x, y] = 522) or (Sdata[CurScene, 0, x, y] = 1022) or ((Sdata[CurScene, 0, x, y] >= 1324) and (Sdata[CurScene, 0, x, y] <= 1330)) or (Sdata[CurScene, 0, x, y] = 1348) then
    Result := False;
  //if SData[CurScene, 0, x, y] = 1358 * 2 then result := true;
  if (MODVersion = 23) and ((Sdata[CurScene, 1, x, y] = 1358 * 2) or (Sdata[CurScene, 1, x, y] = 1269 * 2)) then
    Result := True;

end;

function CanWalkInScene(x1, y1, x, y: integer): boolean; overload;
begin
  Result := (abs(Sdata[CurScene, 4, x, y] - Sdata[CurScene, 4, x1, y1]) <= 10) and CanWalkInScene(x, y);

end;

//检查是否有第1类事件, 如有则调用
function CheckEvent1: boolean;
var
  x, y: integer;
begin
  x := Sx;
  y := Sy;
  case SFace of
    0: x := x - 1;
    1: y := y + 1;
    2: y := y - 1;
    3: x := x + 1;
  end;
  Result := False;
  //如有则调用事件
  if Sdata[CurScene, 3, x, y] >= 0 then
  begin
    CurEvent := Sdata[CurScene, 3, x, y];
    if Ddata[CurScene, CurEvent, 2] >= 0 then
    begin
      Cx := Sx;
      Cy := Sy;
      CallEvent(Ddata[CurScene, Sdata[CurScene, 3, x, y], 2]);
      Result := True;
    end;
  end;
  CurEvent := -1;
end;

//检查是否有第3类事件, 如有则调用
procedure CheckEvent3;
var
  enum: integer;
begin
  enum := Sdata[CurScene, 3, Sx, Sy];
  if (enum >= 0) and (Ddata[CurScene, enum, 4] > 0) then
  begin
    CurEvent := enum;
    Cx := Sx;
    Cy := Sy;
    CallEvent(Ddata[CurScene, enum, 4]);
    CurEvent := -1;
  end;
end;

//Menus.
//通用选单, (位置(x, y), 宽度, 最大选项(编号均从0开始))
//使用前必须设置选单使用的字符串组才有效, 字符串组不可越界使用
function CommonMenu(x, y, w, max, default: integer; menuString: array of utf8string): integer; overload;
var
  menuEngString: array of utf8string;
begin
  setlength(menuEngString, 0);
  Result := CommonMenu(x, y, w, max, default, menuString, menuEngString);
end;

function CommonMenu(x, y, w, max: integer; menuString: array of utf8string): integer; overload;
begin
  Result := CommonMenu(x, y, w, max, 0, menuString);
end;

function CommonMenu(x, y, w, max: integer; menuString, menuEngString: array of utf8string): integer; overload;
begin
  Result := CommonMenu(x, y, w, max, 0, menuString, menuEngString);
end;

function CommonMenu(x, y, w, max, default: integer; menuString, menuEngString: array of utf8string): integer; overload;
var
  menu, menup: integer;
begin
  menu := default;
  RecordFreshScreen(x, y, w + 1, max * 22 + 29);
  ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
  SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
        if ((event.key.key = SDLK_ESCAPE)) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + max * 22 + 29) then
          begin
            Result := menu;
            //Redraw;
            //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - y - 2) div 22;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
            SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          end;
        end;
      end;
    end;
  end;

  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.key := 0;
  event.button.button := 0;

end;

//该选单即时产生显示效果, 由函数指定
function CommonMenu(x, y, w, max, default: integer; menuString, menuEngString: array of utf8string; fn: TPInt1): integer; overload;
var
  menu, menup: integer;
begin
  menu := default;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
  SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
  fn(menu);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          fn(menu);
        end;
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          fn(menu);
        end;
        if ((event.key.key = SDLK_ESCAPE)) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - y - 2) div 22;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
            SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
            fn(menu);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.key := 0;
  event.button.button := 0;
end;

//显示通用选单(位置, 宽度, 最大值)
//这个通用选单包含两个字符串组, 可分别显示中文和英文
procedure ShowCommonMenu(x, y, w, max, menu: integer; menuString: array of utf8string); overload;
var
  menuEngString: array of utf8string;
begin
  setlength(menuEngString, 0);
  ShowCommonMenu(x, y, w, max, menu, menuString, menuEngString);
end;

procedure ShowCommonMenu(x, y, w, max, menu: integer; menuString, menuEngString: array of utf8string); overload;
var
  i, p: integer;
  temp: PSDL_Surface;
begin
  LoadFreshScreen(x, y, w + 1, max * 22 + 29);
  DrawRectangle(screen, x, y, w, max * 22 + 28, 0, ColColor(255), 50);
  if (length(menuEngString) > 0) and (length(menuString) = length(menuEngString)) then
    p := 1
  else
    p := 0;
  for i := 0 to min(max, length(menuString) - 1) do
    if i = menu then
    begin
      DrawShadowText(screen, menuString[i], x + 3, y + 2 + 22 * i, ColColor($64), ColColor($66));
      if p = 1 then
        DrawEngShadowText(screen, menuEngString[i], x + 93, y + 2 + 22 * i, ColColor($64), ColColor($66));
    end
    else
    begin
      DrawShadowText(screen, menuString[i], x + 3, y + 2 + 22 * i, ColColor($5), ColColor($7));
      if p = 1 then
        DrawEngShadowText(screen, menuEngString[i], x + 93, y + 2 + 22 * i, ColColor($5), ColColor($7));
    end;

end;

//卷动选单
function CommonScrollMenu(x, y, w, max, maxshow: integer; menuString: array of utf8string): integer; overload;
var
  menuEngString: array of utf8string;
begin
  setlength(menuEngString, 0);
  Result := CommonScrollMenu(x, y, w, max, maxshow, menuString, menuEngString);
end;

function CommonScrollMenu(x, y, w, max, maxshow: integer; menuString, menuEngString: array of utf8string): integer; overload;
var
  menu, menup, menutop: integer;
begin
  menu := 0;
  menutop := 0;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  RecordFreshScreen(x, y, w + 1, max * 22 + 29);
  ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
  SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu - menutop >= maxshow then
          begin
            menutop := menutop + 1;
          end;
          if menu > max then
          begin
            menu := 0;
            menutop := 0;
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu <= menutop then
          begin
            menutop := menu;
          end;
          if menu < 0 then
          begin
            menu := max;
            menutop := menu - maxshow + 1;
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.key = SDLK_PAGEDOWN) then
        begin
          menu := menu + maxshow;
          menutop := menutop + maxshow;
          if menu > max then
          begin
            menu := max;
          end;
          if menutop > max - maxshow + 1 then
          begin
            menutop := max - maxshow + 1;
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.key = SDLK_PAGEUP) then
        begin
          menu := menu - maxshow;
          menutop := menutop - maxshow;
          if menu < 0 then
          begin
            menu := 0;
          end;
          if menutop < 0 then
          begin
            menutop := 0;
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if ((event.key.key = SDLK_ESCAPE)) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + max * 22 + 29) then
          begin
            Result := menu;
            //Redraw;
            //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_WHEEL:
      begin
        if (event.wheel.y < 0) then
        begin
          menu := menu + 1;
          if menu - menutop >= maxshow then
          begin
            menutop := menutop + 1;
          end;
          if menu > max then
          begin
            menu := 0;
            menutop := 0;
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.wheel.y > 0) then
        begin
          menu := menu - 1;
          if menu <= menutop then
          begin
            menutop := menu;
          end;
          if menu < 0 then
          begin
            menu := max;
            menutop := menu - maxshow + 1;
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - y - 2) div 22 + menutop;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menuString, menuEngString);
            SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.key := 0;
  event.button.button := 0;

end;

procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer; menuString, menuEngString: array of utf8string);
var
  i, p: integer;
begin
  LoadFreshScreen(x, y, w + 1, max * 22 + 29);
  if max + 1 < maxshow then
    maxshow := max + 1;
  DrawRectangle(screen, x, y, w, maxshow * 22 + 6, 0, ColColor(255), 50);
  if (length(menuEngString) > 0) and (length(menuString) = length(menuEngString)) then
    p := 1
  else
    p := 0;
  for i := menutop to menutop + maxshow - 1 do
    if (i = menu) and (i < length(menuString)) then
    begin
      DrawShadowText(screen, menuString[i], x + 3, y + 2 + 22 * (i - menutop), ColColor($64), ColColor($66));
      if p = 1 then
        DrawEngShadowText(screen, menuEngString[i], x + 93, y + 2 + 22 * (i - menutop), ColColor($64), ColColor($66));
    end
    else
    begin
      DrawShadowText(screen, menuString[i], x + 3, y + 2 + 22 * (i - menutop), ColColor($5), ColColor($7));
      if p = 1 then
        DrawEngShadowText(screen, menuEngString[i], x + 93, y + 2 + 22 * (i - menutop), ColColor($5), ColColor($7));
    end;

end;

//仅有两个选项的横排选单, 为美观使用横排
//此类选单中每个选项限制为两个中文字, 仅适用于提问'继续', '取消'的情况
function CommonMenu2(x, y, w: integer; menuString: array of utf8string): integer;
var
  menu, menup: integer;
begin
  menu := 0;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  RecordFreshScreen(x, y, w + 1, 29);
  ShowCommonMenu2(x, y, w, menu, menuString);
  SDL_UpdateRect2(screen, x, y, w + 1, 29);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_LEFT) or (event.key.key = SDLK_RIGHT) then
        begin
          if menu = 1 then
            menu := 0
          else
            menu := 1;
          ShowCommonMenu2(x, y, w, menu, menuString);
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
        end;
        if ((event.key.key = SDLK_ESCAPE)) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + 29) then
          begin
            Result := menu;
            //Redraw;
            //SDL_UpdateRect2(screen, x, y, w + 1, 29);
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= x) and (round(event.button.x / (RESOLUTIONX / screen.w)) < x + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > y) and (round(event.button.y / (RESOLUTIONY / screen.h)) < y + 29) then
        begin
          menup := menu;
          menu := (round(event.button.x / (RESOLUTIONX / screen.w)) - x - 2) div 50;
          if menu > 1 then
            menu := 1;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            ShowCommonMenu2(x, y, w, menu, menuString);
            SDL_UpdateRect2(screen, x, y, w + 1, 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.key := 0;
  event.button.button := 0;

end;

//显示仅有两个选项的横排选单
procedure ShowCommonMenu2(x, y, w, menu: integer; menuString: array of utf8string);
var
  i, p: integer;
begin
  LoadFreshScreen(x, y, w + 1, 29);
  DrawRectangle(screen, x, y, w, 28, 0, ColColor(255), 50);
  //if length(Menuengstring) > 0 then p := 1 else p := 0;
  for i := 0 to 1 do
    if i = menu then
    begin
      DrawShadowText(screen, menuString[i], x + 3 + i * 50, y + 2, ColColor($64), ColColor($66));
    end
    else
    begin
      DrawShadowText(screen, menuString[i], x + 3 + i * 50, y + 2, ColColor($5), ColColor($7));
    end;

end;

//选择一名队员, 可以附带两个属性显示
function SelectOneTeamMember(x, y: integer; str: utf8string; list1, list2: integer): integer;
var
  i, Amount: integer;
  menuString, menuEngString: array of utf8string;
begin
  setlength(menuString, 6);
  if str <> '' then
    setlength(menuEngString, 6)
  else
    setlength(menuEngString, 0);
  Amount := 0;

  for i := 0 to 5 do
  begin
    if teamlist[i] >= 0 then
    begin
      menuString[i] := cp950toutf8(@Rrole[teamlist[i]].Name);
      if str <> '' then
      begin
        menuEngString[i] := format(str, [Rrole[teamlist[i]].Data[list1], Rrole[teamlist[i]].Data[list2]]);
      end;
      Amount := Amount + 1;
    end;
  end;
  if str = '' then
    Result := CommonMenu(x, y, 105, Amount - 1, menuString, menuEngString)
  else
    Result := CommonMenu(x, y, 105 + length(menuEngString[0]) * 10, Amount - 1, menuString, menuEngString);

end;

//主选单
procedure MenuEsc;
var
  word: array [0 .. 6] of utf8string;
  i: integer;
begin
  NeedRefreshScene := 0;
  word[0] := '醫療';
  word[1] := '解毒';
  word[2] := '物品';
  word[3] := '狀態';
  word[4] := '離隊';
  word[5] := '系統';
  //word[5] := '傳送';
  if MODVersion = 22 then
    word[4] := '特殊';

  i := 0;
  while i >= 0 do
  begin
    i := CommonMenu(27, 30, 46, 5, i, word);
    case i of
      0: MenuMedcine;
      1: MenuMedPoison;
      2: MenuItem;
      6: begin
        Teleport;
        //Redraw; SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        break;
      end;
      5: MenuSystem;
      4: MenuLeave;
      3:
      begin
        if MODVersion = 51 then
        begin
          //ReFreshScreen;
          CallEvent(1092);
          Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end
        else
          MenuStatus;
      end;
    end;
    Redraw;
    SDL_UpdateRect2(screen, 80, 0, screen.w - 80, screen.h);
    if (where = 3) then
      break;
  end;
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  NeedRefreshScene := 1;
  {SDL_EnableKeyRepeat(0, 0);
    //DrawMMap;
    showMenu(menu);
    //SDL_EventState(SDL_EVENT_KEY_DOWN,SDL_IGNORE);
    while (SDL_WaitEvent(@event)) do
    begin
    if where >= 3 then
    begin
    break;
    end;
    CheckBasicEvent;
    case event.type_ of
    SDL_EVENT_KEY_UP:
    begin
    if (event.key.key = sdlk_down) then
    begin
    menu := menu + 1;
    if menu > 5 - 0 * 2 then
    menu := 0;
    showMenu(menu);
    end;
    if (event.key.key = sdlk_up) then
    begin
    menu := menu - 1;
    if menu < 0 then
    menu := 5 - 0 * 2;
    showMenu(menu);
    end;
    if (event.key.key = sdlk_escape) then
    begin
    ReDraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    break;
    end;
    if (event.key.key = sdlk_return) or (event.key.key = sdlk_space) then
    begin
    case menu of
    0: MenuMedcine;
    1: MenuMedPoison;
    2: MenuItem;
    5: MenuSystem;
    4: MenuLeave;
    3: MenuStatus;
    end;
    showmenu(menu);
    end;
    end;
    SDL_EVENT_MOUSE_BUTTON_UP:
    begin
    if event.button.button = sdl_button_right then
    begin
    ReDraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    break;
    end;
    if event.button.button = sdl_button_left then
    begin
    if (round(event.button.y / (resolutiony / screen.h)) > 32) and (round(event.button.y / (resolutiony / screen.h)) < 32 + 22 * (6 - 0 * 2))
    and (round(event.button.x / (resolutionx / screen.w)) > 27) and (round(event.button.x / (resolutionx / screen.w)) < 27 + 46) then
    begin
    showmenu(menu);
    case menu of
    0: MenuMedcine;
    1: MenuMedPoison;
    2: MenuItem;
    5: MenuSystem;
    4: MenuLeave;
    3: MenuStatus;
    end;
    showmenu(menu);
    end;
    end;
    end;
    SDL_EVENT_MOUSE_MOTION:
    begin
    if (round(event.button.y / (resolutiony / screen.h)) > 32) and (round(event.button.y / (resolutiony / screen.h)) < 32 + 22 * 6)
    and (round(event.button.x / (resolutionx / screen.w)) > 27) and (round(event.button.x / (resolutionx / screen.w)) < 27 + 46) then
    begin
    menup := menu;
    menu := (round(event.button.y / (resolutiony / screen.h)) - 32) div 22;
    if menu > 5 - 0 * 2 then
    menu := 5 - 0 * 2;
    if menu < 0 then
    menu := 0;
    if menup <> menu then
    showmenu(menu);
    end;
    end;

    end;
    end;
    event.key.key := 0;
    event.button.button := 0;
    SDL_EnableKeyRepeat(50, 30);}

end;

//显示主选单
procedure ShowMenu(menu: integer);
var
  word: array [0 .. 5] of utf8string;
  i, max: integer;
begin
  word[0] := '醫療';
  word[1] := '解毒';
  word[2] := '物品';
  word[3] := '狀態';
  word[4] := '離隊';
  word[5] := '系統';
  if MODVersion = 22 then
    word[4] := '特殊';
  if where = 0 then
    max := 5
  else
    max := 5;
  //LoadFreshScreen(27, 30, 47, max * 22 + 29);
  Redraw;
  DrawRectangle(screen, 27, 30, 46, max * 22 + 28, 0, ColColor(255), 50);
  //当前所在位置用白色, 其余用黄色
  for i := 0 to max do
    if i = menu then
    begin
      //drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($66));
      DrawShadowText(screen, word[i], 30, 32 + 22 * i, ColColor($64), ColColor($66));
    end
    else
    begin
      //drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($7));
      DrawShadowText(screen, word[i], 30, 32 + 22 * i, ColColor($5), ColColor($7));
    end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//医疗选单, 需两次选择队员
procedure MenuMedcine;
var
  role1, role2, menu: integer;
  str: utf8string;
begin
  str := '隊員醫療能力';
  DrawTextWithRect(screen, str, 80, 30, 132, ColColor($21), ColColor($23));
  menu := SelectOneTeamMember(80, 65, '%4d', 46, 0);
  //ShowMenu(0);
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := teamlist[menu];
    str := '隊員目前生命';
    DrawTextWithRect(screen, str, 230, 30, 132, ColColor($21), ColColor($23));
    menu := SelectOneTeamMember(230, 65, '%4d/%4d', 17, 18);
    if menu >= 0 then
    begin
      role2 := teamlist[menu];
      EffectMedcine(role1, role2);
    end;
  end;
  //waitanykey;
  //ReFreshScreen;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//解毒选单
procedure MenuMedPoison;
var
  role1, role2, menu: integer;
  str: utf8string;
begin
  str := '隊員解毒能力';
  DrawTextWithRect(screen, str, 80, 30, 132, ColColor($21), ColColor($23));
  menu := SelectOneTeamMember(80, 65, '%4d', 48, 0);
  //ShowMenu(1);
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := teamlist[menu];
    str := '隊員中毒程度';
    DrawTextWithRect(screen, str, 230, 30, 132, ColColor($21), ColColor($23));
    menu := SelectOneTeamMember(230, 65, '%4d', 20, 0);
    if menu >= 0 then
    begin
      role2 := teamlist[menu];
      EffectMedPoison(role1, role2);
    end;
  end;
  //waitanykey;
  //ReFreshScreen;
  //showmenu(1);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//物品选单
function MenuItem: boolean;
var
  point, atlu, x, y, col, row, xp, yp, iamount, menu, max, i, xm, ym, w: integer;
  //point似乎未使用, atlu为处于左上角的物品在列表中的序号, x, y为光标位置
  //col, row为总列数和行数
  menuString: array of utf8string;
begin
  col := 14;
  row := 5;
  x := 0;
  y := 0;
  w := col * 42 + 8;
  //setlength(Menuengstring, 0);
  case where of
    0, 1:
    begin
      max := 6;
      setlength(menuString, max + 1);
      menuString[0] := '全部物品';
      menuString[1] := '劇情物品';
      menuString[2] := '神兵寶甲';
      menuString[3] := '武功秘笈';
      menuString[4] := '靈丹妙藥';
      menuString[5] := '傷人暗器';
      menuString[6] := '整理物品';
      xm := 80;
      ym := 30;
    end;
    2:
    begin
      max := 1;
      setlength(menuString, max + 1);
      menuString[0] := '靈丹妙藥';
      menuString[1] := '傷人暗器';
      xm := 150;
      ym := 150;
    end;
  end;

  menu := 0;
  while menu >= 0 do
  begin
    menu := CommonMenu(xm, ym, 87, max, menu, menuString);

    case where of
      0, 1:
      begin
        if menu = 0 then
          i := 100
        else
          i := menu - 1;
      end;
      2:
      begin
        if menu >= 0 then
          i := menu + 3;
      end;
    end;

    if menu < 0 then
      Result := False;
    if menu = 6 then
    begin
      ReArrangeItem(1);
      Redraw;
    end;

    if (menu >= 0) and (menu < 6) then
    begin
      Redraw;
      RecordFreshScreen(0, 0, screen.w, screen.h);
      iamount := ReadItemList(i);
      atlu := 0;
      ShowMenuItem(row, col, x, y, atlu);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      while (SDL_WaitEvent(@event)) do
      begin
        CheckBasicEvent;
        case event.type_ of
          SDL_EVENT_KEY_UP:
          begin
            if (event.key.key = SDLK_DOWN) then
            begin
              y := y + 1;
              if y < 0 then
                y := 0;
              if (y >= row) then
              begin
                if (ItemList[atlu + col * row] >= 0) then
                  atlu := atlu + col;
                y := row - 1;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.key = SDLK_UP) then
            begin
              y := y - 1;
              if y < 0 then
              begin
                y := 0;
                if atlu > 0 then
                  atlu := atlu - col;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.key = SDLK_PAGEDOWN) then
            begin
              //y := y + row;
              atlu := atlu + col * row;
              if y < 0 then
                y := 0;
              if (ItemList[atlu + col * row] < 0) and (iamount > col * row) then
              begin
                y := y - (iamount - atlu) div col - 1 + row;
                atlu := (iamount div col - row + 1) * col;
                if y >= row then
                  y := row - 1;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.key = SDLK_PAGEUP) then
            begin
              //y := y - row;
              atlu := atlu - col * row;
              if atlu < 0 then
              begin
                y := y + atlu div col;
                atlu := 0;
                if y < 0 then
                  y := 0;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.key = SDLK_RIGHT) then
            begin
              x := x + 1;
              if x >= col then
                x := 0;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.key = SDLK_LEFT) then
            begin
              x := x - 1;
              if x < 0 then
                x := col - 1;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.key = SDLK_ESCAPE) then
            begin
              //ReDraw;
              //ShowMenu(2);
              Result := False;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
            begin
              //ReDraw;
              CurItem := RItemlist[ItemList[(y * col + x + atlu)]].Number;
              if (where <> 2) and (CurItem >= 0) and (ItemList[(y * col + x + atlu)] >= 0) then
                UseItem(CurItem);
              //ShowMenu(2);
              Result := True;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              break;
            end;
          end;
          SDL_EVENT_MOUSE_BUTTON_UP:
          begin
            if (event.button.button = SDL_BUTTON_RIGHT) then
            begin
              //ReDraw;
              //ShowMenu(2);
              Result := False;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.button.button = SDL_BUTTON_LEFT) and (CellPhone = 0) then
            begin
              if (round(event.button.x / (RESOLUTIONX / screen.w)) >= 110) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 496) and (round(event.button.y / (RESOLUTIONY / screen.h)) > 90) and (round(event.button.y / (RESOLUTIONY / screen.h)) < 308) then
              begin
                //ReDraw;
                CurItem := RItemlist[ItemList[(y * col + x + atlu)]].Number;
                if (where <> 2) and (CurItem >= 0) and (ItemList[(y * col + x + atlu)] >= 0) then
                  UseItem(CurItem);
                //ShowMenu(2);
                Result := True;
                //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
                break;
              end;
            end;
          end;
          SDL_EVENT_MOUSE_WHEEL:
          begin
            if (event.wheel.y < 0) then
            begin
              y := y + 1;
              if y < 0 then
                y := 0;
              if (y >= row) then
              begin
                if (ItemList[atlu + col * row] >= 0) then
                  atlu := atlu + col;
                y := row - 1;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.wheel.y > 0) then
            begin
              y := y - 1;
              if y < 0 then
              begin
                y := 0;
                if atlu > 0 then
                  atlu := atlu - col;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
          SDL_EVENT_MOUSE_MOTION:
          begin
            if (round(event.button.x / (RESOLUTIONX / screen.w)) >= 110) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 110 + w) and (round(event.button.y / (RESOLUTIONY / screen.h)) > 90) and (round(event.button.y / (RESOLUTIONY / screen.h)) < 308) then
            begin
              xp := x;
              yp := y;
              x := (round(event.button.x / (RESOLUTIONX / screen.w)) - 115) div 42;
              y := (round(event.button.y / (RESOLUTIONY / screen.h)) - 95) div 42;
              if x >= col then
                x := col - 1;
              if y >= row then
                y := row - 1;
              if x < 0 then
                x := 0;
              if y < 0 then
                y := 0;
              //鼠标移动时仅在x, y发生变化时才重画
              if (x <> xp) or (y <> yp) then
              begin
                ShowMenuItem(row, col, x, y, atlu);
                SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              end;
            end;
            if (round(event.button.x / (RESOLUTIONX / screen.w)) >= 110) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 496) and (round(event.button.y / (RESOLUTIONY / screen.h)) > 308) then
            begin
              //atlu := atlu+col;
              if (ItemList[atlu + col * row] >= 0) then
                atlu := atlu + col;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (round(event.button.x / (RESOLUTIONX / screen.w)) >= 110) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 496) and (round(event.button.y / (RESOLUTIONY / screen.h)) < 90) then
            begin
              if atlu > 0 then
                atlu := atlu - col;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        end;
      end;
    end;
    Redraw;
    if where = 2 then
      break;
    ShowMenu(2);
  end;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//读物品列表, 主要是战斗中需屏蔽一部分物品
//利用一个不可能用到的数值（100）, 表示读取所有物品
function ReadItemList(ItemType: integer): integer;
var
  i, p: integer;
begin
  p := 0;
  for i := 0 to length(ItemList) - 1 do
    ItemList[i] := -1;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if (RItemlist[i].Number >= 0) then
    begin
      if (Ritem[RItemlist[i].Number].ItemType = ItemType) or (ItemType = 100) then
      begin
        ItemList[p] := i;
        p := p + 1;
      end;
    end;
  end;
  Result := p;

end;

//显示物品选单
procedure ShowMenuItem(row, col, x, y, atlu: integer);
var
  item, i, i1, i2, len, len2, len3, listnum, w: integer;
  str: utf8string;
  words: array [0 .. 10] of utf8string;
  words2: array [0 .. 22] of utf8string;
  words3: array [0 .. 12] of utf8string;
  p2: array [0 .. 22] of integer;
  p3: array [0 .. 12] of integer;
  color1, color2: integer;
begin
  words[0] := '劇情物品';
  words[1] := '神兵寶甲';
  words[2] := '武功秘笈';
  words[3] := '靈丹妙藥';
  words[4] := '傷人暗器';
  words2[0] := '生命';
  words2[1] := '生命';
  words2[2] := '中毒';
  words2[3] := '體力';
  words2[4] := '內力';
  words2[5] := '內力';
  words2[6] := '內力';
  words2[7] := '攻擊';
  words2[8] := '輕功';
  words2[9] := '防禦';
  words2[10] := '醫療';
  words2[11] := '用毒';
  words2[12] := '解毒';
  words2[13] := '抗毒';
  words2[14] := '拳掌';
  words2[15] := '御劍';
  words2[16] := '耍刀';
  words2[17] := '特殊';
  words2[18] := '暗器';
  words2[19] := '武學';
  words2[20] := '品德';
  words2[21] := '左右';
  words2[22] := '帶毒';

  words3[0] := '內力';
  words3[1] := '內力';
  words3[2] := '攻擊';
  words3[3] := '輕功';
  words3[4] := '用毒';
  words3[5] := '醫療';
  words3[6] := '解毒';
  words3[7] := '拳掌';
  words3[8] := '御劍';
  words3[9] := '耍刀';
  words3[10] := '特殊';
  words3[11] := '暗器';
  words3[12] := '資質';

  if MODVersion = 22 then
  begin
    words2[4] := '靈力';
    words2[5] := '靈力';
    words2[6] := '靈力';
    words2[7] := '武力';
    words2[8] := '移動';
    words2[10] := '仙術';
    words2[11] := '毒術';
    words2[14] := '火系';
    words2[15] := '水系';
    words2[16] := '雷系';
    words2[17] := '土系';
    words2[18] := '射擊';

    words3[0] := '靈力';
    words3[1] := '靈力';
    words3[2] := '武力';
    words3[3] := '移動';
    words3[4] := '毒術';
    words3[5] := '仙術';
    words3[7] := '火系';
    words3[8] := '水系';
    words3[9] := '雷系';
    words3[10] := '土系';
    words3[11] := '射擊';
    words3[12] := '智力';
  end;
  w := col * 42 + 8;
  LoadFreshScreen(0, 0, screen.w, screen.h);
  DrawRectangle(screen, 110, 30, w, 25, 0, ColColor(255), 50);
  DrawRectangle(screen, 110, 60, w, 25, 0, ColColor(255), 50);
  DrawRectangle(screen, 110, 90, w, 218, 0, ColColor(255), 50);
  DrawRectangle(screen, 110, 313, w, 25, 0, ColColor(255), 50);
  //i:=0;
  for i1 := 0 to row - 1 do
    for i2 := 0 to col - 1 do
    begin
      listnum := ItemList[i1 * col + i2 + atlu];
      if (RItemlist[listnum].Number >= 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
      begin
        if (i1 = y) and (i2 = x) then
          DrawIPic(RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95, 0, 0, 0, 0)
        else
          DrawIPic(RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95, 0, 25, 0, 15);
      end;
    end;
  listnum := ItemList[y * col + x + atlu];
  if (listnum >= 0) and (listnum < MAX_ITEM_AMOUNT) then
    item := RItemlist[listnum].Number
  else
    item := -1;

  if (RItemlist[listnum].Amount > 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
  begin
    str := format('%5d', [RItemlist[listnum].Amount]);
    DrawEngShadowText(screen, str, 110 + w - 80, 32, ColColor($64), ColColor($66));
    len := length(putf8char(@Ritem[item].Name));
    DrawBig5ShadowText(screen, @Ritem[item].Name, 110 + w div 2 - len * 5, 32, ColColor($21), ColColor($23));
    len := length(putf8char(@Ritem[item].Introduction));
    DrawBig5ShadowText(screen, @Ritem[item].Introduction, 110 + w div 2 - len * 5, 62, ColColor($5), ColColor($7));
    DrawShadowText(screen, words[Ritem[item].ItemType], 117, 315, ColColor($21), ColColor($23));
    //如有人使用则显示
    if Ritem[item].User >= 0 then
    begin
      str := '使用人：';
      DrawShadowText(screen, str, 207, 315, ColColor($21), ColColor($23));
      DrawBig5ShadowText(screen, @Rrole[Ritem[item].User].Name, 297, 315, ColColor($64), ColColor($66));
    end;
    //如是罗盘则显示坐标
    if item = COMPASS_ID then
    begin
      str := '你的位置：';
      DrawShadowText(screen, str, 207, 315, ColColor($21), ColColor($23));
      str := format('%3d, %3d', [My, Mx]);
      DrawEngShadowText(screen, str, 317, 315, ColColor($64), ColColor($66));
    end;
  end;

  if (item >= 0) and (Ritem[item].ItemType > 0) then
  begin
    len2 := 0;
    for i := 0 to 22 do
    begin
      p2[i] := 0;
      if (Ritem[item].Data[45 + i] <> 0) and (i <> 4) then
      begin
        p2[i] := 1;
        len2 := len2 + 1;
      end;
    end;
    if Ritem[item].ChangeMPType = 2 then
    begin
      p2[4] := 1;
      len2 := len2 + 1;
    end;

    len3 := 0;
    for i := 0 to 12 do
    begin
      p3[i] := 0;
      if (Ritem[item].Data[69 + i] <> 0) and (i <> 0) then
      begin
        p3[i] := 1;
        len3 := len3 + 1;
      end;
    end;
    if (Ritem[item].NeedMPType in [0, 1]) and (Ritem[item].ItemType <> 3) then
    begin
      p3[0] := 1;
      len3 := len3 + 1;
    end;

    if len2 + len3 > 0 then
      DrawRectangle(screen, 110, 344, w, 20 * ((len2 + 5) div 6 + (len3 + 5) div 6) + 5, 0, ColColor(255), 50);

    i1 := 0;
    for i := 0 to 22 do
    begin
      if (p2[i] = 1) then
      begin
        str := format('%6d', [Ritem[item].Data[45 + i]]);
        if i = 4 then
          case Ritem[item].ChangeMPType of
            0: str := '    陰';
            1: str := '    陽';
            2: str := '  調和';
          end;
        if (i = 0) or (i = 5) then
        begin
          color1 := ColColor($10);
          color2 := ColColor($13);
        end
        else
        begin
          color1 := ColColor($64);
          color2 := ColColor($66);
        end;
        DrawShadowText(screen, words2[i], 117 + i1 mod 6 * 95, i1 div 6 * 20 + 346, ColColor($5), ColColor($7));
        DrawShadowText(screen, str, 137 + i1 mod 6 * 95, i1 div 6 * 20 + 346, color1, color2);
        i1 := i1 + 1;
      end;
    end;

    i1 := 0;
    for i := 0 to 12 do
    begin
      if (p3[i] = 1) then
      begin
        str := format('%6d', [Ritem[item].Data[69 + i]]);
        if i = 0 then
          case Ritem[item].NeedMPType of
            0: str := '    陰';
            1: str := '    陽';
            2: str := '  調和';
          end;
        if (i = 1) then
        begin
          color1 := ColColor($10);
          color2 := ColColor($13);
        end
        else
        begin
          color1 := ColColor($64);
          color2 := ColColor($66);
        end;
        DrawShadowText(screen, words3[i], 117 + i1 mod 6 * 95, ((len2 + 5) div 6 + i1 div 6) * 20 + 346, ColColor($50), ColColor($4E));
        DrawShadowText(screen, str, 137 + i1 mod 6 * 95, ((len2 + 5) div 6 + i1 div 6) * 20 + 346, color1, color2);
        i1 := i1 + 1;
      end;
    end;
  end;

  DrawItemFrame(x, y);

end;

//画白色边框作为物品选单的光标
procedure DrawItemFrame(x, y: integer);
var
  i, xp, yp, d: integer;
  t: byte;
  c: uint32;
begin
  xp := 110;
  yp := 60;
  d := 42;
  for i := 0 to 39 do
  begin
    t := 250 - i * 3;
    c := SDL_MapSurfaceRGB(screen, t, t, t);
    PutPixel(screen, x * d + 6 + i + xp, y * d + 36 + yp, c);
    PutPixel(screen, x * d + 6 + 39 - i + xp, y * d + 36 + 39 + yp, c);
    PutPixel(screen, x * d + 6 + xp, y * d + 36 + i + yp, c);
    PutPixel(screen, x * d + 6 + 39 + xp, y * d + 36 + 39 - i + yp, c);
  end;

end;

//使用物品
procedure UseItem(inum: integer);
var
  x, y, menu, rnum, p: integer;
  str, str1: utf8string;
  menuString: array of utf8string;
begin
  CurItem := inum;
  Redraw;
  case Ritem[inum].ItemType of
    0: //剧情物品
    begin
      //如某属性大于0, 直接调用事件
      if Ritem[inum].UnKnow7 > 0 then
        CallEvent(Ritem[inum].UnKnow7)
      else
      begin
        if where = 1 then
        begin
          x := Sx;
          y := Sy;
          case SFace of
            0: x := x - 1;
            1: y := y + 1;
            2: y := y - 1;
            3: x := x + 1;
          end;
          //如面向位置有第2类事件则调用
          if Sdata[CurScene, 3, x, y] >= 0 then
          begin
            CurEvent := Sdata[CurScene, 3, x, y];
            if Ddata[CurScene, CurEvent, 3] >= 0 then
            begin
              Cx := Sx;
              Cy := Sy;
              CallEvent(Ddata[CurScene, CurEvent, 3]);
            end;
          end;
          CurEvent := -1;
        end;
      end;
    end;
    1: //装备
    begin
      menu := 1;
      if Ritem[inum].User >= 0 then
      begin
        Redraw;
        setlength(menuString, 2);
        menuString[0] := '取消';
        menuString[1] := '繼續';
        str := '此物品正有人裝備，是否繼續？';
        DrawTextWithRect(screen, str, 80, 30, 285, ColColor(5), ColColor(7));
        menu := CommonMenu(80, 65, 45, 1, menuString);
      end;
      if menu = 1 then
      begin
        Redraw;
        str := '誰要裝備';
        str1 := cp950toutf8(@Ritem[inum].Name);
        DrawTextWithRect(screen, str, 80, 30, length(str1) * 22 + 80, ColColor($21), ColColor($23));
        DrawShadowText(screen, str1, 160, 32, ColColor($64), ColColor($66));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        menu := SelectOneTeamMember(80, 65, '', 0, 0);
        if menu >= 0 then
        begin
          rnum := teamlist[menu];
          p := Ritem[inum].EquipType;
          if (p < 0) or (p > 1) then
            p := 0;
          if CanEquip(rnum, inum) then
          begin
            if Ritem[inum].User >= 0 then
              Rrole[Ritem[inum].User].Equip[p] := -1;
            if Rrole[rnum].Equip[p] >= 0 then
              Ritem[Rrole[rnum].Equip[p]].User := -1;
            Rrole[rnum].Equip[p] := inum;
            Ritem[inum].User := rnum;
          end
          else
          begin
            str := '此人不適合裝備此物品';
            DrawTextWithRect(screen, str, 80, 230, 205, ColColor($64), ColColor($66));
            WaitAnyKey;
            Redraw;
            //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
          end;
        end;
      end;
    end;
    2: //秘笈
    begin
      menu := 1;
      if Ritem[inum].User >= 0 then
      begin
        Redraw;
        setlength(menuString, 2);
        menuString[0] := '取消';
        menuString[1] := '繼續';
        str := '此秘笈正有人修煉，是否繼續？';
        DrawTextWithRect(screen, str, 80, 30, 285, ColColor(5), ColColor(7));
        menu := CommonMenu(80, 65, 45, 1, menuString);
      end;
      if menu = 1 then
      begin
        Redraw;
        str := '誰要修煉';
        str1 := cp950toutf8(@Ritem[inum].Name);
        DrawTextWithRect(screen, str, 80, 30, length(str1) * 22 + 80, ColColor($21), ColColor($23));
        DrawShadowText(screen, str1, 160, 32, ColColor($64), ColColor($66));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        menu := SelectOneTeamMember(80, 65, '', 0, 0);
        if menu >= 0 then
        begin
          rnum := teamlist[menu];
          if CanEquip(rnum, inum) then
          begin
            if Ritem[inum].User >= 0 then
              Rrole[Ritem[inum].User].PracticeBook := -1;
            if Rrole[rnum].PracticeBook >= 0 then
              Ritem[Rrole[rnum].PracticeBook].User := -1;
            Rrole[rnum].PracticeBook := inum;
            Ritem[inum].User := rnum;
            {if (inum in [78, 93]) then
              rrole[rnum].Sexual := 2;}
          end
          else
          begin
            str := '此人不適合修煉此秘笈';
            DrawTextWithRect(screen, str, 80, 230, 205, ColColor($64), ColColor($66));
            WaitAnyKey;
            Redraw;
            //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
          end;
        end;
      end;
    end;
    3: //药品
    begin
      if where <> 2 then
      begin
        str := '誰要服用';
        str1 := cp950toutf8(@Ritem[inum].Name);
        DrawTextWithRect(screen, str, 80, 30, length(str1) * 22 + 80, ColColor($21), ColColor($23));
        DrawShadowText(screen, str1, 160, 32, ColColor($64), ColColor($66));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        menu := SelectOneTeamMember(80, 65, '', 0, 0);
      end;
      if menu >= 0 then
      begin
        Redraw;
        rnum := teamlist[menu];
        EatOneItem(rnum, inum);
        instruct_32(inum, -1);
        WaitAnyKey;
      end;
    end;
    4: //不处理暗器类物品
    begin
      //if where<>3 then break;
    end;
  end;

end;

//能否装备
function CanEquip(rnum, inum: integer): boolean;
var
  i, r: integer;
  menuString: array [0 .. 2] of utf8string;
  str: utf8string;
begin

  //判断是否符合
  //注意这里对'所需属性'为负值时均添加原版类似资质的处理

  Result := True;

  if sign(Ritem[inum].NeedMP) * Rrole[rnum].CurrentMP < Ritem[inum].NeedMP then
    Result := False;
  if sign(Ritem[inum].NeedAttack) * Rrole[rnum].Attack < Ritem[inum].NeedAttack then
    Result := False;
  if sign(Ritem[inum].NeedSpeed) * Rrole[rnum].Speed < Ritem[inum].NeedSpeed then
    Result := False;
  if sign(Ritem[inum].NeedUsePoi) * Rrole[rnum].UsePoi < Ritem[inum].NeedUsePoi then
    Result := False;
  if sign(Ritem[inum].NeedMedcine) * Rrole[rnum].Medcine < Ritem[inum].NeedMedcine then
    Result := False;
  if sign(Ritem[inum].NeedMedPoi) * Rrole[rnum].MedPoi < Ritem[inum].NeedMedPoi then
    Result := False;
  if sign(Ritem[inum].NeedFist) * Rrole[rnum].Fist < Ritem[inum].NeedFist then
    Result := False;
  if sign(Ritem[inum].NeedSword) * Rrole[rnum].Sword < Ritem[inum].NeedSword then
    Result := False;
  if sign(Ritem[inum].NeedKnife) * Rrole[rnum].Knife < Ritem[inum].NeedKnife then
    Result := False;
  if sign(Ritem[inum].NeedUnusual) * Rrole[rnum].Unusual < Ritem[inum].NeedUnusual then
    Result := False;
  if sign(Ritem[inum].NeedHidWeapon) * Rrole[rnum].HidWeapon < Ritem[inum].NeedHidWeapon then
    Result := False;
  if sign(Ritem[inum].NeedAptitude) * Rrole[rnum].Aptitude < Ritem[inum].NeedAptitude then
    Result := False;

  //内力性质
  if (Rrole[rnum].MPType < 2) and (Ritem[inum].NeedMPType < 2) then
    if Rrole[rnum].MPType <> Ritem[inum].NeedMPType then
      Result := False;

  //如有专用人物, 前面的都作废
  if (Ritem[inum].OnlyPracRole >= 0) and (Result = True) then
    if (Ritem[inum].OnlyPracRole = rnum) then
      Result := True
    else
      Result := False;

  //如已有10种武功, 且物品也能练出武功, 则结果为假
  r := 0;
  for i := 0 to 9 do
    if Rrole[rnum].Magic[i] > 0 then
      r := r + 1;
  if (r >= 10) and (Ritem[inum].Magic > 0) then
    Result := False;

  //如果已有秘籍所练出的武功且小于10级, 则为真
  for i := 0 to 9 do
    if (Rrole[rnum].Magic[i] = Ritem[inum].Magic) and (Rrole[rnum].MagLevel[i] < 900) then
    begin
      Result := True;
      break;
    end;

  //如果以上判定为真, 且属于自宫物品, 则提问, 若选否则为假
  if (inum in [78, 93]) and (Result = True) and (Rrole[rnum].Sexual <> 2) then
  begin
    Redraw;
    menuString[0] := '取消';
    menuString[1] := '繼續';
    str := '是否自宮？';
    DrawTextWithRect(screen, str, 80, 30, 105, ColColor(7), ColColor(5));
    if CommonMenu(80, 65, 45, 1, menuString) = 1 then
      Rrole[rnum].Sexual := 2
    else
      Result := False;
  end;

end;

//查看状态选单
procedure MenuStatus;
var
  str: utf8string;
  menu, Amount, i: integer;
  menuString, menuEngString: array of utf8string;
begin
  str := '查看隊員狀態';
  Redraw;
  RecordFreshScreen(0, 0, screen.w, screen.h);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  DrawTextWithRect(screen, str, 10, 30, 132, ColColor($21), ColColor($23));
  setlength(menuString, 6);
  setlength(menuEngString, 0);
  Amount := 0;

  for i := 0 to 5 do
  begin
    if teamlist[i] >= 0 then
    begin
      menuString[i] := cp950toutf8(@Rrole[teamlist[i]].Name);
      Amount := Amount + 1;
    end;
  end;

  menu := CommonMenu(10, 65, 85, Amount - 1, 0, menuString, menuEngString, @ShowStatusByTeam);
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //menu := SelectOneTeamMember(27, 65, '%3d', 15, 0);
  {if menu >= 0 then
    begin
    ShowStatus(TeamList[menu]);
    waitanykey;
    redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;}

end;

//显示状态
procedure ShowStatusByTeam(tnum: integer);
begin
  if teamlist[tnum] >= 0 then
    ShowStatus(teamlist[tnum], 100, 65);
end;

procedure ShowStatus(rnum: integer); overload;
begin
  ShowStatus(rnum, CENTER_X - 273, 65);
end;

procedure ShowStatus(rnum, x, y: integer); overload;
var
  i, magicnum, mlevel, needexp: integer;
  p: array [0 .. 10] of integer;
  addatk, adddef, addspeed: integer;
  str: utf8string;
  strs: array [0 .. 21] of utf8string;
  color1, color2: uint32;
  Name: utf8string;
begin
  strs[0] := '等級';
  strs[1] := '生命';
  strs[2] := '內力';
  strs[3] := '體力';
  strs[4] := '經驗';
  strs[5] := '升級';
  strs[6] := '攻擊';
  strs[7] := '防禦';
  strs[8] := '輕功';
  strs[9] := '醫療能力';
  strs[10] := '用毒能力';
  strs[11] := '解毒能力';
  strs[12] := '拳掌功夫';
  strs[13] := '御劍能力';
  strs[14] := '耍刀技巧';
  strs[15] := '特殊兵器';
  strs[16] := '暗器技巧';
  strs[17] := '裝備物品';
  strs[18] := '修煉物品';
  strs[19] := '所會武功';
  strs[20] := '受傷';
  strs[21] := '中毒';

  if MODVersion = 22 then
  begin
    strs[2] := '靈力';
    strs[6] := '武力';
    strs[8] := '移動';
    strs[9] := '仙術能力';
    strs[10] := '毒術能力';
    strs[12] := '火系能力';
    strs[13] := '水系能力';
    strs[14] := '雷系能力';
    strs[15] := '土系能力';
    strs[16] := '射擊能力';
    strs[19] := '所會法術';
  end;

  p[0] := 43;
  p[1] := 45;
  p[2] := 44;
  p[3] := 46;
  p[4] := 47;
  p[5] := 48;
  p[6] := 50;
  p[7] := 51;
  p[8] := 52;
  p[9] := 53;
  p[10] := 54;

  if where <= 2 then
    LoadFreshScreen(0, 0, screen.w, screen.h);

  DrawRectangle(screen, x, y, 525, 315, 0, ColColor(255), 50);

  //显示头像
  DrawHeadPic(Rrole[rnum].HeadNum, x + 60, y + 80);
  //显示姓名
  Name := cp950toutf8(@Rrole[rnum].Name, 5);
  DrawShadowText(screen, Name, x + 88 - DrawLength(Name) * 5, y + 85, ColColor($66), ColColor($63));
  //显示所需字符
  for i := 0 to 5 do
    DrawShadowText(screen, strs[i], x + 10, y + 110 + 21 * i, ColColor($21), ColColor($23));
  for i := 6 to 16 do
    DrawShadowText(screen, strs[i], x + 180, y + 5 + 21 * (i - 6), ColColor($64), ColColor($66));
  DrawShadowText(screen, strs[19], x + 360, y + 5, ColColor($21), ColColor($23));

  addatk := 0;
  adddef := 0;
  addspeed := 0;
  if Rrole[rnum].Equip[0] >= 0 then
  begin
    addatk := addatk + Ritem[Rrole[rnum].Equip[0]].AddAttack;
    adddef := adddef + Ritem[Rrole[rnum].Equip[0]].AddDefence;
    addspeed := addspeed + Ritem[Rrole[rnum].Equip[0]].addspeed;
  end;

  if Rrole[rnum].Equip[1] >= 0 then
  begin
    addatk := addatk + Ritem[Rrole[rnum].Equip[1]].AddAttack;
    adddef := adddef + Ritem[Rrole[rnum].Equip[1]].AddDefence;
    addspeed := addspeed + Ritem[Rrole[rnum].Equip[1]].addspeed;
  end;

  //攻击, 防御, 轻功
  //单独处理是因为显示顺序和存储顺序不同
  str := format('%4d', [Rrole[rnum].Attack + addatk]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 0, ColColor($5), ColColor($7));
  str := format('%4d', [Rrole[rnum].Defence + adddef]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 1, ColColor($5), ColColor($7));
  str := format('%4d', [Rrole[rnum].Speed + addspeed]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 2, ColColor($5), ColColor($7));

  //其他属性
  str := format('%4d', [Rrole[rnum].Medcine]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 3, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].UsePoi]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 4, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].MedPoi]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 5, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].Fist]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 6, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].Sword]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 7, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].Knife]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 8, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].Unusual]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 9, ColColor($5), ColColor($7));

  str := format('%4d', [Rrole[rnum].HidWeapon]);
  DrawEngShadowText(screen, str, x + 280, y + 5 + 21 * 10, ColColor($5), ColColor($7));

  //武功
  for i := 0 to 9 do
  begin
    magicnum := Rrole[rnum].Magic[i];
    if magicnum > 0 then
    begin
      DrawBig5ShadowText(screen, @Rmagic[magicnum].Name, x + 360, y + 26 + 21 * i, ColColor($5), ColColor($7));
      str := format('%3d', [Rrole[rnum].MagLevel[i] div 100 + 1]);
      DrawEngShadowText(screen, str, x + 480, y + 26 + 21 * i, ColColor($64), ColColor($66));
    end;
  end;
  str := format('%4d', [Rrole[rnum].Level]);
  DrawEngShadowText(screen, str, x + 110, y + 110, ColColor($5), ColColor($7));
  //生命值, 在受伤和中毒值不同时使用不同颜色
  case Rrole[rnum].Hurt of
    34 .. 66:
    begin
      color1 := ColColor($E);
      color2 := ColColor($10);
    end;
    67 .. 1000:
    begin
      color1 := ColColor($14);
      color2 := ColColor($16);
    end;
    else
    begin
      color1 := ColColor($7);
      color2 := ColColor($5);
    end;
  end;
  str := format('%4d', [Rrole[rnum].CurrentHP]);
  DrawEngShadowText(screen, str, x + 60, y + 131, color1, color2);

  str := '/';
  DrawEngShadowText(screen, str, x + 100, y + 131, ColColor($64), ColColor($66));

  case Rrole[rnum].Poison of
    34 .. 66:
    begin
      color1 := ColColor($30);
      color2 := ColColor($32);
    end;
    67 .. 1000:
    begin
      color1 := ColColor($35);
      color2 := ColColor($37);
    end;
    else
    begin
      color1 := ColColor($21);
      color2 := ColColor($23);
    end;
  end;
  str := format('%4d', [Rrole[rnum].MaxHP]);
  DrawEngShadowText(screen, str, x + 110, y + 131, color1, color2);
  //内力, 依据内力性质使用颜色
  if Rrole[rnum].MPType = 0 then
  begin
    color1 := ColColor($50);
    color2 := ColColor($4E);
  end
  else if Rrole[rnum].MPType = 1 then
  begin
    color1 := ColColor($5);
    color2 := ColColor($7);
  end
  else
  begin
    color1 := ColColor($64);
    color2 := ColColor($66);
  end;
  str := format('%4d/%4d', [Rrole[rnum].CurrentMP, Rrole[rnum].MaxMP]);
  DrawEngShadowText(screen, str, x + 60, y + 152, color1, color2);
  //体力
  str := format('%4d/%4d', [Rrole[rnum].PhyPower, MAX_PHYSICAL_POWER]);
  DrawEngShadowText(screen, str, x + 60, y + 173, ColColor($5), ColColor($7));
  //经验
  str := format('%5d', [uint16(Rrole[rnum].Exp)]);
  DrawEngShadowText(screen, str, x + 100, y + 194, ColColor($5), ColColor($7));
  str := format('%5d', [uint16(leveluplist[Rrole[rnum].Level - 1])]);
  DrawEngShadowText(screen, str, x + 100, y + 215, ColColor($5), ColColor($7));

  //str:=format('%5d', [Rrole[rnum,21]]);
  //drawengshadowtext(@str[1],150,295,colcolor($7),colcolor($5));

  //drawshadowtext(@strs[20, 1], 30, 341, colcolor($23), colcolor($21));
  //drawshadowtext(@strs[21, 1], 30, 362, colcolor($23), colcolor($21));

  //drawrectanglewithoutframe(100,351,Rrole[rnum,19],10,colcolor($16),50);
  //中毒, 受伤
  //str := format('%4d', [RRole[rnum].Hurt]);
  //drawengshadowtext(@str[1], 150, 341, colcolor($14), colcolor($16));
  //str := format('%4d', [RRole[rnum].Poison]);
  //drawengshadowtext(@str[1], 150, 362, colcolor($35), colcolor($37));

  //装备, 秘笈
  DrawShadowText(screen, strs[17], x + 180, y + 240, ColColor($21), ColColor($23));
  DrawShadowText(screen, strs[18], x + 360, y + 240, ColColor($21), ColColor($23));
  if Rrole[rnum].Equip[0] >= 0 then
    DrawBig5ShadowText(screen, @Ritem[Rrole[rnum].Equip[0]].Name, x + 190, y + 261, ColColor($5), ColColor($7));
  if Rrole[rnum].Equip[1] >= 0 then
    DrawBig5ShadowText(screen, @Ritem[Rrole[rnum].Equip[1]].Name, x + 190, y + 282, ColColor($5), ColColor($7));

  //计算秘笈需要经验
  if Rrole[rnum].PracticeBook >= 0 then
  begin
    mlevel := 1;
    magicnum := Ritem[Rrole[rnum].PracticeBook].Magic;
    if magicnum > 0 then
      for i := 0 to 9 do
        if Rrole[rnum].Magic[i] = magicnum then
        begin
          mlevel := Rrole[rnum].MagLevel[i] div 100 + 1;
          break;
        end;
    needexp := mlevel * Ritem[Rrole[rnum].PracticeBook].needexp * (7 - Rrole[rnum].Aptitude div 15);
    DrawBig5ShadowText(screen, @Ritem[Rrole[rnum].PracticeBook].Name, x + 370, y + 261, ColColor($5), ColColor($7));
    str := format('%5d/%5d', [uint16(Rrole[rnum].ExpForBook), needexp]);
    if mlevel = 10 then
      str := format('%5d/=', [uint16(Rrole[rnum].ExpForBook)]);
    DrawEngShadowText(screen, str, x + 380, y + 282, ColColor($64), ColColor($66));
  end;

  SDL_UpdateRect2(screen, x, y, 536, 316);

end;

//显示简单状态(x, y表示位置)
procedure ShowSimpleStatus(rnum, x, y: integer);
var
  i, magicnum: integer;
  p: array [0 .. 10] of integer;
  str: utf8string;
  strs: array [0 .. 3] of utf8string;
  color1, color2: uint32;
begin
  strs[0] := '等級';
  strs[1] := '生命';
  strs[2] := '內力';
  strs[3] := '體力';
  if MODVersion = 22 then
  begin
    strs[2] := '靈力';
  end;

  DrawRectangle(screen, x, y, 145, 173, 0, ColColor(255), 50);
  DrawHeadPic(Rrole[rnum].HeadNum, x + 50, y + 63);
  str := cp950toutf8(@Rrole[rnum].Name, 5);
  DrawShadowText(screen, str, x + 80 - DrawLength(str) * 5, y + 65, ColColor($64), ColColor($66));
  for i := 0 to 3 do
    DrawShadowText(screen, strs[i], x + 3, y + 86 + 21 * i, ColColor($21), ColColor($23));

  str := format('%9d', [Rrole[rnum].Level]);
  DrawEngShadowText(screen, str, x + 50, y + 86, ColColor($5), ColColor($7));

  case Rrole[rnum].Hurt of
    34 .. 66:
    begin
      color1 := ColColor($E);
      color2 := ColColor($10);
    end;
    67 .. 1000:
    begin
      color1 := ColColor($14);
      color2 := ColColor($16);
    end;
    else
    begin
      color1 := ColColor($5);
      color2 := ColColor($7);
    end;
  end;
  str := format('%4d', [Rrole[rnum].CurrentHP]);
  DrawEngShadowText(screen, str, x + 50, y + 107, color1, color2);

  str := '/';
  DrawEngShadowText(screen, str, x + 90, y + 107, ColColor($64), ColColor($66));

  case Rrole[rnum].Poison of
    34 .. 66:
    begin
      color1 := ColColor($30);
      color2 := ColColor($32);
    end;
    67 .. 1000:
    begin
      color1 := ColColor($35);
      color2 := ColColor($37);
    end;
    else
    begin
      color1 := ColColor($21);
      color2 := ColColor($23);
    end;
  end;
  str := format('%4d', [Rrole[rnum].MaxHP]);
  DrawEngShadowText(screen, str, x + 100, y + 107, color1, color2);

  //str:=format('%4d/%4d', [Rrole[rnum,17],Rrole[rnum,18]]);
  //drawengshadowtext(@str[1],x+50,y+107,colcolor($7),colcolor($5));
  if Rrole[rnum].MPType = 0 then
  begin
    color1 := ColColor($50);
    color2 := ColColor($4E);
  end
  else if Rrole[rnum].MPType = 1 then
  begin
    color1 := ColColor($5);
    color2 := ColColor($7);
  end
  else
  begin
    color1 := ColColor($64);
    color2 := ColColor($66);
  end;
  str := format('%4d/%4d', [Rrole[rnum].CurrentMP, Rrole[rnum].MaxMP]);
  DrawEngShadowText(screen, str, x + 50, y + 128, color1, color2);
  str := format('%9d', [Rrole[rnum].PhyPower]);
  DrawEngShadowText(screen, str, x + 50, y + 149, ColColor($5), ColColor($7));

  //SDL_UpdateRect2(screen, x, y, 146, 174);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

//离队选单
procedure MenuLeave;
var
  str: utf8string;
  i, menu: integer;
begin
  if (where = 0) or (MODVersion = 22) then
  begin
    str := '要求誰離隊？';
    if MODVersion = 22 then
      str := '選擇一個隊友';
    DrawTextWithRect(screen, str, 80, 30, 132, ColColor($21), ColColor($23));
    menu := SelectOneTeamMember(80, 65, '%3d', 15, 0);
    if menu >= 0 then
    begin
      for i := 0 to 99 do
        if leavelist[i] = teamlist[menu] then
        begin
          Redraw;
          CallEvent(BEGIN_LEAVE_EVENT + i * 2);
          //Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          //SDL_EnableKeyRepeat(0, 10);
          break;
        end;
    end;
  end
  else
  begin
    str := '場景內不可離隊！';
    DrawTextWithRect(screen, str, 80, 30, 172, ColColor($21), ColColor($23));
    WaitAnyKey;
  end;
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

//系统选单
procedure MenuSystem;
var
  word: array [0 .. 3] of utf8string;
  i: integer;
begin
  word[0] := '讀取';
  word[1] := '存檔';
  word[2] := '傳送';
  word[3] := '離開';
  if FULLSCREEN = 1 then
    word[2] := '窗口';

  i := 0;
  while i >= 0 do
  begin
    i := CommonMenu(80, 30, 46, 3, i, word);

    case i of
      3: MenuQuit;
      1: MenuSave;
      0: MenuLoad;
      2:
      begin
        if where = 0 then
        begin
          Teleport;
          Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
      end;
    end;
    if where = 3 then
      break;
    Redraw;
    SDL_UpdateRect2(screen, 133, 0, screen.w - 133, screen.h);
  end;

end;

{var
  i, menu, menup: integer;
  begin
  menu := 0;
  showmenusystem(menu);
  while (SDL_WaitEvent(@event)) do
  begin
  if where = 3 then
  break;
  CheckBasicEvent;
  case event.type_ of
  SDL_EVENT_KEY_UP:
  begin
  if (event.key.key = sdlk_down) then
  begin
  menu := menu + 1;
  if menu > 3 then
  menu := 0;
  showMenusystem(menu);
  end;
  if (event.key.key = sdlk_up) then
  begin
  menu := menu - 1;
  if menu < 0 then
  menu := 3;
  showMenusystem(menu);
  end;
  if (event.key.key = sdlk_escape) then
  begin
  redraw;
  SDL_UpdateRect2(screen, 80, 30, 47, 95);
  break;
  end;
  if (event.key.key = sdlk_return) or (event.key.key = sdlk_space) then
  begin
  case menu of
  3:
  begin
  MenuQuit;
  end;
  1:
  begin
  MenuSave;
  end;
  0:
  begin
  Menuload;
  end;
  2:
  begin
  SwitchFullScreen;
  break;
  end;
  end;
  end;
  end;
  SDL_EVENT_MOUSE_BUTTON_UP:
  begin
  if (event.button.button = sdl_button_right) then
  begin
  redraw;
  SDL_UpdateRect2(screen, 80, 30, 47, 95);
  break;
  end;
  if (event.button.button = sdl_button_left) then
  case menu of
  3:
  begin
  MenuQuit;
  end;
  1:
  begin
  MenuSave;
  end;
  0:
  begin
  Menuload;
  end;
  2:
  begin
  SwitchFullScreen;
  break;
  end;
  end;
  end;
  SDL_EVENT_MOUSE_MOTION:
  begin
  if (round(event.button.x / (resolutionx / screen.w)) >= 80) and (round(event.button.x / (resolutionx / screen.w)) < 127)
  and (round(event.button.y / (resolutiony / screen.h)) > 47) and (round(event.button.y / (resolutiony / screen.h)) < 120) then
  begin
  menup := menu;
  menu := (round(event.button.y / (resolutiony / screen.h)) - 32) div 22;
  if menu > 3 then
  menu := 3;
  if menu < 0 then
  menu := 0;
  if menup <> menu then
  showMenusystem(menu);
  end;
  end;
  end;
  end;

  end;}

//显示系统选单
procedure ShowMenuSystem(menu: integer);
{var
  word: array[0..3] of utf8string;
  i: integer;}
begin
  {Word[0] := ' 讀取');
    Word[1] := ' 存檔');
    Word[2] := ' 全屏');
    Word[3] := ' 離開');
    if fullscreen = 1 then
    Word[2] := ' 窗口');

    DrawRectangle(80, 30, 46, 92, 0, colcolor(255), 30);
    for i := 0 to 3 do
    if i = menu then
    begin
    drawtext(screen, @word[i][1], 64, 32 + 22 * i, colcolor($64));
    drawtext(screen, @word[i][1], 63, 32 + 22 * i, colcolor($66));
    end
    else
    begin
    drawtext(screen, @word[i][1], 64, 32 + 22 * i, colcolor($5));
    drawtext(screen, @word[i][1], 63, 32 + 22 * i, colcolor($7));
    end;
    SDL_UpdateRect2(screen, 80, 30, 47, 93);}

end;

//读档选单
procedure MenuLoad;
var
  menu, nowwhere, i: integer;
  menuString: array [0 .. 10] of utf8string;
  filename: utf8string;
begin
  nowwhere := where;
  //setlength(menustring, 6);
  //setlength(Menuengstring, 0);
  //setlength(menuengstring, 0);
  menuString[0] := '進度一';
  menuString[1] := '進度二';
  menuString[2] := '進度三';
  menuString[3] := '進度四';
  menuString[4] := '進度五';
  menuString[5] := '進度六';
  menuString[6] := '進度七';
  menuString[7] := '進度八';
  menuString[8] := '進度九';
  menuString[9] := '進度十';
  menuString[10] := '自動檔';
  for i := 0 to 10 do
  begin
    filename := AppPath + 'save/r' + IntToStr(i + 1) + '.grp';
    if FileExists(filename) then
      menuString[i] := menuString[i] + ' ' + FormatDateTime('yyyy-mm-dd hh:mm:ss', FileDateToDateTime(FileAge(filename)))
    else
      menuString[i] := menuString[i] + ' -------------------';
  end;
  menu := CommonMenu(133, 30, 267, 10, menuString);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    if where = 1 then
    begin
      InitialScene;
      //Redraw;
      //ShowSceneName(CurScene);
    end;
    Redraw(1);
    if nowwhere = 1 then
      ShowSceneName(CurScene);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  //edraw;
  ShowMenu(5);
  ShowMenuSystem(0);

end;

//特殊的读档选单, 仅用在开始时读档
function MenuLoadAtBeginning: integer;
var
  menu, i: integer;
  menuString: array [0 .. 10] of utf8string;
  filename: utf8string;
begin
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //setlength(menustring, 6);
  //setlength(Menuengstring, 0);
  menuString[0] := '載入進度一';
  menuString[1] := '載入進度二';
  menuString[2] := '載入進度三';
  menuString[3] := '載入進度四';
  menuString[4] := '載入進度五';
  menuString[5] := '載入進度六';
  menuString[6] := '載入進度七';
  menuString[7] := '載入進度八';
  menuString[8] := '載入進度九';
  menuString[9] := '載入進度十';
  menuString[10] := '載入自動檔';

  for i := 0 to 10 do
  begin
    filename := AppPath + 'save/r' + IntToStr(i + 1) + '.grp';
    if FileExists(filename) then
      menuString[i] := menuString[i] + ' ' + FormatDateTime('yyyy-mm-dd hh:mm:ss', FileDateToDateTime(FileAge(filename)))
    else
      menuString[i] := menuString[i] + ' -------------------';
  end;

  //writeln(pword(@menustring[0][2])^);
  menu := CommonMenu(CENTER_X - 150, CENTER_Y - 100, 307, 10, menuString);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    //where := 0;
    instruct_14;
    //Redraw;
    //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  Result := menu;
end;

//存档选单
procedure MenuSave;
var
  menu, i: integer;
  menuString: array [0 .. 9] of utf8string;
  filename: utf8string;
begin
  //setlength(menustring, 5);
  //setlength(menuengstring, 0);
  menuString[0] := '進度一';
  menuString[1] := '進度二';
  menuString[2] := '進度三';
  menuString[3] := '進度四';
  menuString[4] := '進度五';
  menuString[5] := '進度六';
  menuString[6] := '進度七';
  menuString[7] := '進度八';
  menuString[8] := '進度九';
  menuString[9] := '進度十';
  for i := 0 to 9 do
  begin
    filename := AppPath + 'save/r' + IntToStr(i + 1) + '.grp';
    if FileExists(filename) then
      menuString[i] := menuString[i] + ' ' + FormatDateTime('yyyy-mm-dd hh:mm:ss', FileDateToDateTime(FileAge(filename)))
    else
      menuString[i] := menuString[i] + ' -------------------';
  end;
  menu := CommonMenu(133, 30, 267, 9, menuString);
  if menu >= 0 then
    SaveR(menu + 1);
  //Redraw;
  ShowMenu(5);
  ShowMenuSystem(1);
end;

//退出选单
procedure MenuQuit;
var
  menu, i: integer;
  str1, str2: utf8string;
  str: utf8string;
  menuString: array [0 .. 2] of utf8string;
begin
  //setlength(menustring, 3);
  //setlength(menuengstring, 0);
  menuString[0] := '取消';
  menuString[1] := '確認';
  menuString[2] := '腳本';
  menu := CommonMenu(133, 30, 45, 2, menuString);
  if menu = 1 then
  begin
    where := 3;
    //instruct_14;
    exit;
    //Quit;
  end;

  if menu = 2 then
  begin
    str := '  Script fail!';
    str1 := '';
    //str1 := inputbox('Script file number:', str1, '1');
    str2 := '';
    i := EnterNumber(0, 99, 300, 100, 1);
    if ExecScript(putf8char(AppPath + 'script/1.lua'), putf8char('f' + IntToStr(i))) <> 0 then
    begin
      DrawTextWithRect(screen, str, 100, 200, 150, $FFFFFFFF, $FFFFFFFF);
      WaitAnyKey;
    end;
  end;
  if menu <> 1 then
  begin
    ShowMenu(5);
    ShowMenuSystem(3);
  end;
end;

//医疗的效果
//未添加体力的需求与消耗
function EffectMedcine(role1, role2: integer): integer;
var
  word: utf8string;
  addlife, minushurt: integer;
begin
  addlife := Rrole[role1].Medcine * MED_LIFE * (10 - Rrole[role2].Hurt div 15) div 10;
  if Rrole[role2].Hurt - Rrole[role1].Medcine > 20 then
    addlife := 0;
  minushurt := addlife div LIFE_HURT;
  if minushurt > Rrole[role2].Hurt then
    minushurt := Rrole[role2].Hurt;
  Rrole[role2].Hurt := Rrole[role2].Hurt - minushurt;
  if Rrole[role2].Hurt < 0 then
    Rrole[role2].Hurt := 0;
  if addlife > Rrole[role2].MaxHP - Rrole[role2].CurrentHP then
    addlife := Rrole[role2].MaxHP - Rrole[role2].CurrentHP;
  Rrole[role2].CurrentHP := Rrole[role2].CurrentHP + addlife;
  Result := addlife;

  if where <> 2 then
  begin
    Redraw;
    DrawRectangle(screen, 115, 98, 155, 76, 0, ColColor(255), 30);
    DrawBig5ShadowText(screen, @Rrole[role2].Name, 120, 100, ColColor($21), ColColor($23));
    word := '增加生命';
    DrawShadowText(screen, word, 120, 125, ColColor($5), ColColor($7));
    word := format('%4d', [addlife]);
    DrawEngShadowText(screen, word, 220, 125, ColColor($64), ColColor($66));
    word := '減少受傷';
    DrawShadowText(screen, word, 120, 150, ColColor($5), ColColor($7));
    word := format('%4d', [minushurt]);
    DrawEngShadowText(screen, word, 220, 150, ColColor($64), ColColor($66));
    ShowSimpleStatus(role2, 350, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
  end;

end;

//解毒的效果
function EffectMedPoison(role1, role2: integer): integer;
var
  word: utf8string;
  minuspoi: integer;
begin
  minuspoi := Rrole[role1].MedPoi;
  if minuspoi > Rrole[role2].Poison then
    minuspoi := Rrole[role2].Poison;
  Rrole[role2].Poison := Rrole[role2].Poison - minuspoi;
  Result := minuspoi;

  if where <> 2 then
  begin
    Redraw;
    DrawRectangle(screen, 115, 98, 155, 51, 0, ColColor(255), 30);
    word := '減少中毒';
    DrawShadowText(screen, word, 120, 125, ColColor($5), ColColor($7));
    DrawBig5ShadowText(screen, @Rrole[role2].Name, 120, 100, ColColor($21), ColColor($23));
    word := format('%4d', [minuspoi]);
    DrawEngShadowText(screen, word, 220, 125, ColColor($64), ColColor($66));
    ShowSimpleStatus(role2, 350, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
  end;
end;

//使用物品的效果
//练成秘笈的效果
//返回值: 无武学的秘笈, 如果次数可以将能力提升到顶仍有剩余时, 则返回所需的次数, 避免浪费经验
function EatOneItem(rnum, inum: integer; times: integer = 1; display: integer = 1): integer;
var
  i, p, l, x, y, twoline: integer;
  word: array [0 .. 23] of utf8string;
  addvalue, rolelist: array [0 .. 23] of integer;
  str: utf8string;
begin
  rolelist[0] := 17;
  rolelist[1] := 18;
  rolelist[2] := 20;
  rolelist[3] := 21;
  rolelist[4] := 40;
  rolelist[5] := 41;
  rolelist[6] := 42;
  rolelist[7] := 43;
  rolelist[8] := 44;
  rolelist[9] := 45;
  rolelist[10] := 46;
  rolelist[11] := 47;
  rolelist[12] := 48;
  rolelist[13] := 49;
  rolelist[14] := 50;
  rolelist[15] := 51;
  rolelist[16] := 52;
  rolelist[17] := 53;
  rolelist[18] := 54;
  rolelist[19] := 55;
  rolelist[20] := 56;
  rolelist[21] := 58;
  rolelist[22] := 57;
  rolelist[23] := 19;
  //rolelist:=(17,18,20,21,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,58,57);
  for i := 0 to 22 do
  begin
    if (i <> 4) and (i <> 21) then
      addvalue[i] := Ritem[inum].Data[45 + i] * times
    else
      addvalue[i] := Ritem[inum].Data[45 + i];
  end;
  //减少受伤
  addvalue[23] := -(addvalue[0] div LIFE_HURT);

  if -addvalue[23] > Rrole[rnum].Data[19] then
    addvalue[23] := -Rrole[rnum].Data[19];

  //增加生命, 内力最大值的处理
  if addvalue[1] + Rrole[rnum].Data[18] > MAX_HP then
    addvalue[1] := MAX_HP - Rrole[rnum].Data[18];
  if addvalue[6] + Rrole[rnum].Data[42] > MAX_MP then
    addvalue[6] := MAX_MP - Rrole[rnum].Data[42];
  if addvalue[1] + Rrole[rnum].Data[18] < 0 then
    addvalue[1] := -Rrole[rnum].Data[18];
  if addvalue[6] + Rrole[rnum].Data[42] < 0 then
    addvalue[6] := -Rrole[rnum].Data[42];

  //仅控制不为零的项目
  for i := 7 to 22 do
  begin
    if addvalue[i] <> 0 then
    begin
      if addvalue[i] + Rrole[rnum].Data[rolelist[i]] > MaxProList[rolelist[i]] then
        addvalue[i] := MaxProList[rolelist[i]] - Rrole[rnum].Data[rolelist[i]];
      if addvalue[i] + Rrole[rnum].Data[rolelist[i]] < 0 then
        addvalue[i] := -Rrole[rnum].Data[rolelist[i]];
    end;
  end;
  //生命不能超过最大值
  if addvalue[0] + Rrole[rnum].Data[17] > addvalue[1] + Rrole[rnum].Data[18] then
    addvalue[0] := addvalue[1] + Rrole[rnum].Data[18] - Rrole[rnum].Data[17];
  //中毒不能小于0
  if addvalue[2] + Rrole[rnum].Data[20] < 0 then
    addvalue[2] := -Rrole[rnum].Data[20];
  //体力不能超过100
  if addvalue[3] + Rrole[rnum].Data[21] > MAX_PHYSICAL_POWER then
    addvalue[3] := MAX_PHYSICAL_POWER - Rrole[rnum].Data[21];
  //内力不能超过最大值
  if addvalue[5] + Rrole[rnum].Data[41] > addvalue[6] + Rrole[rnum].Data[42] then
    addvalue[5] := addvalue[6] + Rrole[rnum].Data[42] - Rrole[rnum].Data[41];
  p := 0;
  for i := 0 to 23 do
  begin
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
      p := p + 1;
  end;
  //内力属性
  if (addvalue[4] = 2) and (Rrole[rnum].Data[40] <> 2) then
    p := p + 1;
  //左右互搏
  if (addvalue[21] = 1) and (Rrole[rnum].Data[58] <> 1) then
    p := p + 1;

  if (Ritem[inum].ItemType = 2) and (Ritem[inum].Magic <= 0) then
  begin
    //对次数的修正
    Result := 0;
    for i := 0 to 22 do
    begin
      if (Ritem[inum].Data[45 + i] <> 0) and (i <> 4) and (i <> 21) then
      begin
        Result := max(Result, ceil(abs(addvalue[i] / Ritem[inum].Data[45 + i])));
      end;
    end;
    Result := min(times, Result);
    if p = 0 then
      Result := 0;
  end
  else
    Result := times;
  if display <> 0 then
  begin
    word[0] := '增加生命';
    word[1] := '增加生命最大值';
    word[2] := '中毒程度';
    word[3] := '增加體力';
    word[4] := '內力門路陰陽合一';
    word[5] := '增加內力';
    word[6] := '增加內力最大值';
    word[7] := '增加攻擊力';
    word[8] := '增加輕功';
    word[9] := '增加防禦力';
    word[10] := '增加醫療能力';
    word[11] := '增加用毒能力';
    word[12] := '增加解毒能力';
    word[13] := '增加抗毒能力';
    word[14] := '增加拳掌能力';
    word[15] := '增加御劍能力';
    word[16] := '增加耍刀能力';
    word[17] := '增加特殊兵器';
    word[18] := '增加暗器技巧';
    word[19] := '增加武學常識';
    word[20] := '增加品德指數';
    word[21] := '習得左右互搏';
    word[22] := '增加攻擊帶毒';
    word[23] := '受傷程度';

    if MODVersion = 22 then
    begin
      word[4] := '靈力陰陽合一';
      word[5] := '增加靈力';
      word[6] := '增加靈力最大值';
      word[7] := '增加武力';
      word[8] := '增加移動';
      word[10] := '增加仙術能力';
      word[11] := '增加毒術能力';
      word[14] := '增加火系能力';
      word[15] := '增加水系能力';
      word[16] := '增加雷系能力';
      word[17] := '增加土系能力';
      word[18] := '增加射擊能力';
    end;

    DrawRectangle(screen, 100, 70, 100 + length(putf8char(@Ritem[inum].Name)) * 10, 25, 0, ColColor(255), 50);
    str := '服用';
    if Ritem[inum].ItemType = 2 then
      str := (format('練成%d次', [Result]));
    DrawShadowText(screen, str, 103, 72, ColColor($21), ColColor($23));
    DrawBig5ShadowText(screen, @Ritem[inum].Name, 193, 72, ColColor($64), ColColor($66));

    //如果增加的项超过11个, 分两列显示
    if p < 11 then
    begin
      l := p;
      twoline := 0;
      DrawRectangle(screen, 100, 100, 200, 22 * l + 25, 0, ColColor($FF), 50);
    end
    else
    begin
      l := p div 2 + p mod 2;
      twoline := 1;
      DrawRectangle(screen, 20, 100, 400, 22 * l + 25, 0, ColColor($FF), 50);
    end;
    if twoline = 0 then
      x := 83
    else
      x := 3;
    DrawBig5ShadowText(screen, @Rrole[rnum].Data[4], x + 20, 102, ColColor($21), ColColor($23));
    if p = 0 then
    begin
      str := '未增加屬性';
      DrawShadowText(screen, str, 183, 102, ColColor(5), ColColor(7));
    end;
    p := 0;
    for i := 0 to 23 do
    begin
      if twoline = 0 then
      begin
        x := 0;
        y := 0;
      end
      else
      begin
        if p < l then
        begin
          x := -80;
          y := 0;
        end
        else
        begin
          x := 120;
          y := -l * 22;
        end;
      end;
      if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
      begin
        Rrole[rnum].Data[rolelist[i]] := Rrole[rnum].Data[rolelist[i]] + addvalue[i];
        DrawShadowText(screen, word[i], 103 + x, 124 + y + p * 22, ColColor(5), ColColor(7));
        str := format('%4d', [addvalue[i]]);
        DrawEngShadowText(screen, str, 243 + x, 124 + y + p * 22, ColColor($64), ColColor($66));
        p := p + 1;
      end;
      //对内力性质特殊处理
      if (i = 4) and (addvalue[i] = 2) then
      begin
        if Rrole[rnum].Data[rolelist[i]] <> 2 then
        begin
          Rrole[rnum].Data[rolelist[i]] := 2;
          DrawShadowText(screen, word[i], 103 + x, 124 + y + p * 22, ColColor(5), ColColor(7));
          p := p + 1;
        end;
      end;
      //对左右互搏特殊处理
      if (i = 21) and (addvalue[i] = 1) then
      begin
        if Rrole[rnum].Data[rolelist[i]] <> 1 then
        begin
          Rrole[rnum].Data[rolelist[i]] := 1;
          DrawShadowText(screen, word[i], 103 + x, 124 + y + p * 22, ColColor(5), ColColor(7));
          p := p + 1;
        end;
      end;
    end;
    x := 350;
    if twoline = 1 then
      x := 440;
    ShowSimpleStatus(rnum, x, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;

end;

//Event.
//事件系统
procedure CallEvent(num: integer);
var
  e: array of smallint;
  i, offset, len, p, temppic: integer;
  check: boolean;
  k: array [0 .. 67] of integer;
  filename: utf8string;
begin
  //CurEvent:=num;
  {k[61] := 0;  k[25] := 1;  k[13] := 2;  k[2] := 3;  k[58] := 4;  k[59] := 5;  k[38] := 6;  k[37] := 7;
    k[40] := 8;  k[20] := 9;  k[36] := 10;  k[17] := 11;  k[4] := 12;  k[43] := 13;  k[23] := 14;  k[0] := 15;
    k[39] := 16;  k[66] := 17;  k[31] := 18;  k[1] := 19;  k[45] := 20;  k[16] := 21;  k[47] := 22;  k[65] := 23;
    k[53] := 24;  k[21] := 25;  k[22] := 26;  k[30] := 27;  k[5] := 28;  k[55] := 29;  k[48] := 30;  k[44] := 31;
    k[12] := 32;  k[49] := 33;  k[28] := 34;  k[60] := 35;  k[9] := 36;  k[7] := 37;  k[57] := 38;  k[42] := 39;
    k[67] := 40;  k[56] := 41;  k[34] := 42;  k[24] := 43;  k[33] := 44;  k[14] := 45;  k[18] := 46;  k[8] := 47;
    k[50] := 48;  k[11] := 49;  k[52] := 50;  k[15] := 51;  k[46] := 52;  k[32] := 53;  k[27] := 54;  k[6] := 55;
    k[51] := 56;  k[62] := 57;  k[35] := 58;  k[26] := 59;  k[63] := 60;  k[10] := 61;  k[29] := 62;  k[41] := 63;
    k[19] := 64;  k[54] := 65;  k[64] := 66;  k[3] := 67;}
  SStep := 0;
  CurSceneRolePic := BEGIN_WALKPIC + SFace * 7;
  //redraw;
  //tempPic := CurSceneRolePic;
  //SDL_EnableKeyRepeat(0, 10);

  NeedRefreshScene := 0;
  filename := AppPath + 'script/event/ka' + IntToStr(num) + '.lua';
  if ((KDEF_SCRIPT = 0) or (not FileExists(filename))) then
  begin
    len := 0;
    if num = 0 then
    begin
      offset := 0;
      len := KIdx[0];
    end
    else
    begin
      offset := KIdx[num - 1];
      len := KIdx[num] - offset;
    end;
    setlength(e, len div 2 + 1);
    move(KDef[offset], e[0], len);
    {if MODVersion = 23 then
      begin
      for i := 0 to length div 2 do
      begin
      if (e[i] <= 67) and (e[i] >= 0) then
      e[i] := k[e[i]];
      end;
      end;}
    i := 0;
    len := length(e);
    kyslog('Event %d', [num]);
    //普通事件写成子程, 需跳转事件写成函数
    while SDL_PollEvent(@event) or True do
    begin
      CheckBasicEvent;
      if (i >= len - 1) then
        break;
      if (e[i] < 0) then
        break;
      case e[i] of
        0:
        begin
          i := i + 1;
          instruct_0;
        end;
        1:
        begin
          instruct_1(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        2:
        begin
          instruct_2(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        3:
        begin
          instruct_3([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6], e[i + 7], e[i + 8], e[i + 9], e[i + 10], e[i + 11], e[i + 12], e[i + 13]]);
          i := i + 14;
        end;
        4:
        begin
          i := i + instruct_4(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        5:
        begin
          i := i + instruct_5(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        6:
        begin
          i := i + instruct_6(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
          i := i + 5;
        end;
        7: //Break the event.
        begin
          i := i + 1;
          break;
        end;
        8:
        begin
          instruct_8(e[i + 1]);
          i := i + 2;
        end;
        9:
        begin
          i := i + instruct_9(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        10:
        begin
          instruct_10(e[i + 1]);
          i := i + 2;
        end;
        11:
        begin
          i := i + instruct_11(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        12:
        begin
          instruct_12;
          i := i + 1;
        end;
        13:
        begin
          instruct_13;
          i := i + 1;
        end;
        14:
        begin
          instruct_14;
          i := i + 1;
        end;
        15:
        begin
          instruct_15;
          i := i + 1;
          break;
        end;
        16:
        begin
          i := i + instruct_16(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        17:
        begin
          instruct_17([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]]);
          i := i + 6;
        end;
        18:
        begin
          i := i + instruct_18(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        19:
        begin
          instruct_19(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        20:
        begin
          i := i + instruct_20(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        21:
        begin
          instruct_21(e[i + 1]);
          i := i + 2;
        end;
        22:
        begin
          instruct_22;
          i := i + 1;
        end;
        23:
        begin
          instruct_23(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        24:
        begin
          instruct_24;
          i := i + 1;
        end;
        25:
        begin
          instruct_25(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
          i := i + 5;
        end;
        26:
        begin
          instruct_26(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
          i := i + 6;
        end;
        27:
        begin
          instruct_27(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        28:
        begin
          i := i + instruct_28(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
          i := i + 6;
        end;
        29:
        begin
          i := i + instruct_29(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
          i := i + 6;
        end;
        30:
        begin
          instruct_30(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
          i := i + 5;
        end;
        31:
        begin
          i := i + instruct_31(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        32:
        begin
          instruct_32(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        33:
        begin
          instruct_33(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        34:
        begin
          instruct_34(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        35:
        begin
          instruct_35(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
          i := i + 5;
        end;
        36:
        begin
          i := i + instruct_36(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        37:
        begin
          instruct_37(e[i + 1]);
          i := i + 2;
        end;
        38:
        begin
          instruct_38(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
          i := i + 5;
        end;
        39:
        begin
          instruct_39(e[i + 1]);
          i := i + 2;
        end;
        40:
        begin
          instruct_40(e[i + 1]);
          i := i + 2;
        end;
        41:
        begin
          instruct_41(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        42:
        begin
          i := i + instruct_42(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        43:
        begin
          i := i + instruct_43(e[i + 1], e[i + 2], e[i + 3]);
          i := i + 4;
        end;
        44:
        begin
          instruct_44(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6]);
          i := i + 7;
        end;
        45:
        begin
          instruct_45(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        46:
        begin
          instruct_46(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        47:
        begin
          instruct_47(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        48:
        begin
          instruct_48(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        49:
        begin
          instruct_49(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        50:
        begin
          p := instruct_50([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6], e[i + 7]]);
          i := i + 8;
          if p < 622592 then
            i := i + p
          else
            e[i + ((p + 32768) div 655360) - 1] := p mod 655360;
        end;
        51:
        begin
          instruct_51;
          i := i + 1;
        end;
        52:
        begin
          instruct_52;
          i := i + 1;
        end;
        53:
        begin
          instruct_53;
          i := i + 1;
        end;
        54:
        begin
          instruct_54;
          i := i + 1;
        end;
        55:
        begin
          i := i + instruct_55(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
          i := i + 5;
        end;
        56:
        begin
          instruct_56(e[i + 1]);
          i := i + 2;
        end;
        57:
        begin
          instruct_57;
          i := i + 1;
        end;
        58:
        begin
          instruct_58;
          i := i + 1;
        end;
        59:
        begin
          instruct_59;
          i := i + 1;
        end;
        60:
        begin
          i := i + instruct_60(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
          i := i + 6;
        end;
        61:
        begin
          i := i + instruct_61(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        62:
        begin
          instruct_62(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6]);
          i := i + 7;
          break;
        end;
        63:
        begin
          instruct_63(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        64:
        begin
          instruct_64;
          i := i + 1;
        end;
        65:
        begin
          i := i + 1;
        end;
        66:
        begin
          instruct_66(e[i + 1]);
          i := i + 2;
        end;
        67:
        begin
          instruct_67(e[i + 1]);
          i := i + 2;
        end;
        else
        begin
          i := i + 1;
        end;
      end;
    end;
  end
  else
  begin
    //lua_dofile(Lua_script, AppPath + 'script/oldevent/oldevent_' + inttostr(num));
    if IsConsole then
      writeln('Run event with ', num, '.lua script. ');
    ExecScript(filename, '');
  end;

  //event.key.key := 0;
  //event.button.button := 0;
  //CurSceneRolePic := tempPic;;
  //CurSceneRolePic := 2500 + SFace * 7 + 1;
  //事件执行完之后不刷新场景, 是因为有可能在事件本身包含另一事件, 避免频繁刷新
  if NeedRefreshScene = 1 then
  begin
    InitialScene(0);
  end;
  NeedRefreshScene := 1;
  //if where <> 2 then CurEvent := -1;
  if MMAPAMI * SCENEAMI = 0 then
  begin
    Redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;

end;

procedure CloudCreate(num: integer);
begin
  CloudCreateOnSide(num);
  if (num >= low(Cloud)) and (num <= high(Cloud)) then
    Cloud[num].Positionx := random(17280);

end;

procedure CloudCreateOnSide(num: integer);
begin
  if (num >= low(Cloud)) and (num <= high(Cloud)) then
  begin
    with Cloud[num] do
    begin
      Picnum := random(CPicAmount);
      Shadow := 0;
      Alpha := 10 + random(50);
      mixColor := random(256) + random(256) shl 8 + random(256) shl 16 + random(256) shl 24;
      mixAlpha := 10 + random(50);
      Positionx := 0;
      Positiony := random(8640);
      Speedx := 1 + random(3);
      Speedy := 0;
    end;
  end;
end;

function IsCave(snum: integer): boolean;
begin
  Result := snum in [5, 7, 10, 41, 42, 46, 65, 66, 67, 72, 79];
end;

procedure teleport();
var
  scene_list, scene_list2: array[0..200] of integer;
  i, j, n, notzero, step, x, y, x1, y1: integer;
  strings, stringseng: array of utf8string;

  procedure drawtelemap();
  var
    i, j, x, y: integer;
  begin
    Redraw;
    DrawRectangleWithoutFrame(screen, 0, 0, screen.w, screen.h, $ff000000, 50);
    for x := 0 to 479 do
      for y := 0 to 479 do
      begin
        x1 := center_x - (x - y);
        y1 := (x + y) div 2;
        DrawMPic(earth[x, y] div 2, x1, y1 + 18, 0, 0, 0, 0, -1, 1);
        //if surface[x, y] > 0 then
        //DrawMPic(surface[x, y] div 2, x1, y1 + 18, 0, 0, 0, 0, -1, 1);
        //if building[x, y]>100 then
        //DrawMPic(building[x, y] div 2, x1, y1+18, 0, 0, 0, 0, -1, 1);
      end;
    for i := 0 to SceneAmount - 1 do
    begin
      x := RScene[i].MainEntranceX1;
      y := RScene[i].MainEntranceY1;
      if (x > 0) and (y > 0) then
      begin
        x1 := center_x - (x - y);
        y1 := (x + y) div 2;
        DrawRectangleWithoutFrame(screen, x1, y1, 5, 5, $ffffffff, 50);
        //kyslog('%d %d',[x1,y1]);
      end;
    end;
    x1 := center_x - (mx - my);
    y1 := (mx + my) div 2;
    DrawRectangleWithoutFrame(screen, x1, y1, 5, 5, $ffff0000, 50);
    SDL_Delay(16);
    UpdateAllScreen;
  end;

begin
  while SDL_PollEvent(@event) or True do
  begin
    drawtelemap();
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_DOWN) then
        begin
        end;
        if (event.key.key = SDLK_UP) then
        begin
        end;
        if ((event.key.key = SDLK_ESCAPE)) {and (where <= 2)} then
        begin
          break;
        end;
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          break;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) {and (where <= 2)} then
        begin
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          SDL_GetMouseState2(x1, y1);
          x := (y1 * 2 - x1 + center_x) div 2;
          y := y1 * 2 - x;
          if inregion(x, y, 0, 0, 480, 480) then
          begin
            Mx := x;
            My := y;
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
      end;
    end;
  end;
end;

end.
