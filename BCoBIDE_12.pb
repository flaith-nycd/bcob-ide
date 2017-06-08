;***************
; from ts-soft: http://purebasic.fr/english/viewtopic.php?p=498625#p498625
Procedure SCI_GetTextFormat(ID)
    Protected result
    Select ScintillaSendMessage(ID, #SCI_GETCODEPAGE)
        Case #SC_CP_UTF8
            result = #PB_UTF8
        Default
            result = #PB_Ascii
    EndSelect
    ProcedureReturn result
EndProcedure

Procedure.s SCI_GetGadgetText(ID)
    Protected length, buffer.s
    ; The buffer must be one character larger than the actual length
    length = ScintillaSendMessage(ID, #SCI_GETLENGTH) + 1
    buffer = Space(length)
    ScintillaSendMessage(ID, #SCI_GETTEXT, length, @buffer)
    ProcedureReturn PeekS(@buffer, -1, SCI_GetTextFormat(ID))
EndProcedure
;***************

;-* INCLUDES
IncludeFile "scintilla_constant.pbi"
IncludeFile "scilexer_constant.pbi"

#DLLNAME = "SciLexer.dll"
#DIR_SEP = "/"
#DIR_DLL = "DLL"

CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
    #PROCESSOR_TYPE = "x86"
CompilerElse
    #PROCESSOR_TYPE = "x64"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    #DIRNAME_DLL = #DIR_DLL + #DIR_SEP + #PROCESSOR_TYPE
CompilerElse
    #DIRNAME_DLL = ""
CompilerEndIf

#SCINTILLA_DLL = #DIRNAME_DLL + #DIR_SEP + #DLLNAME

;-* CONSTANTS
#VERSION                = "0.12"
#APP_NAME               = "BCoB-IDE" + " " + #VERSION + " (" + #PROCESSOR_TYPE + ")"
#FONT_NAME_EDITOR       = "IBM 3270";"Lucida Console";"Fira Code";"Source Code Pro";
                                    ; #FONT_NAME_EDITOR       = "PR Number 3";"Print Char 21";"Apple ][";
#FONT_SIZE_EDITOR       = 12
#FONT_SIZE_LINE_NUMBER  = 10

#EXTRA_MARGIN_WIDTH = 3
; Surrounded by 2 lines from the top of the ruler
; we start to draw the generated ruler, the separated line and the caret at this position
#DRAW_AT_POS_Y      = 2

;-* ENUMERATION
Enumeration 200
    #MAIN_WINDOW
    
    #MAIN_MENU
    #MENU_FILE_NEW
    #MENU_FILE_OPEN
    #MENU_FILE_SAVE
    #MENU_FILE_SAVE_AS
    #MENU_FILE_QUIT
    #MENU_EDIT_UNDO
    #MENU_EDIT_REDO
    #MENU_HIGHLIGHT
    
    #SPLIT_LIST_EDITOR
    #LIST_VIEW
    #EDITOR
    #EDITOR_FONT_ID
    
    #TOOL_BAR
    #STATUS_BAR
    
    #SRC_FILE
    
    #EDITOR_IMG_RULER
    #EDITOR_CANVAS_RULER
EndEnumeration

;-* STRUCTURES
Structure CS_MARGIN
    pos.i
    color.i
EndStructure

Structure CS_EDITOR
    id.i
    srcFilename.s
    enabledRuler.i
EndStructure

Structure CS_CANVAS_RULER
    rulerWidth.i
    rulerHeight.i
    rulerTextLength.i
    oneCharWidth.i
    oneCharHeight.i
    marginWidth.i
    drawCharPosY.i
    addCaretPosY.i
EndStructure

;-* GLOBALS
Global.CS_MARGIN NewList Margin()
Global.i ONE_CHAR_WIDTH, MARGIN_WIDTH, DESKTOP_WIDTH, RULER_ON = #False

;-* PROCEDURES
;-**** LOAD SOURCE FILE
Procedure LoadSrcFile(scintillaId.i)
    Protected.i idFile, length, *memory
    Protected.s srcFileName.s
    
    srcFileName = OpenFileRequester("Open a file", "", "cobol (*.cob,*.cbl,*.cpy)|*.cob;*.cbl;*.cpy|All files (*.*)|*.*", 0)
    
    If srcFileName
        idFile = ReadFile(#PB_Any, srcFileName)
        If idFile
            length = Lof(idFile)
            If length
                *memory = AllocateMemory(length + 4)
                If *memory
                    ;Checks if the current file position contains a BOM (Byte Order Mark) 
                    ;and tries to identify the String encoding used in the file. 
                    ReadStringFormat(idFile)
                    
                    ReadData(idFile, *memory, length)
                    
                    ScintillaSendMessage(scintillaId, #nSCI_SETTEXT, length, *memory)
                    
                    FreeMemory(*memory)
                    CloseFile(idFile)
                    ProcedureReturn #True
                EndIf
            EndIf
            CloseFile(idFile)
        EndIf
        ProcedureReturn #False
    EndIf
    ProcedureReturn #False
EndProcedure

;-**** SYNTAX HIGHLIGHTING
Procedure syntaxHighLighting(scintillaId.i, type.i = #True)
    Protected.s KeyWords
    Protected.i iLen
    
    If type
        ;-- TURN LEXER ON
        ScintillaSendMessage(scintillaId, #nSCI_SETLEXER, #nSCLEX_COBOL, 0)         ;built-in COBOL lexer
        ScintillaSendMessage(scintillaId, #nSCI_COLOURISE, 0, -1)                   ;colourize from 0 to end-of-doc
        
        KeyWords = "identification data procedure division program-id working-storage section stop-run if end-if"
        ;         ;Caractére séparant chaque mot de la liste des mots clés
        ;         Define.s KeyWordSep = " "
        ;         ScintillaSendMessage(Gadget, #SCI_AUTOCSETSEPARATOR, Asc(KeyWordSep))
        
        *UTF8 = UTF8(KeyWords)
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_B_KEYWORD, RGB(0, 0, 255))           ;keyword FGcolor
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_B_KEYWORD, RGB(32, 32, 32))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_B_STRING,  RGB(255, 0, 255))         ;string color
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_B_STRING,  RGB(32, 32, 32))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_B_NUMBER,  RGB(192,100,0))           ;number colors
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_B_NUMBER,  RGB(32, 32, 32))
        
        ; # COBOL styles
        ; # 2,Line Comment|3,Doc Comment|4,Number|5,Keyword (A)|6,String|7,Character|8,Extended keyword|9,Preprocessor|10,Operator
        ; # 11,Identifier|16,Keyword (B)
        ; #nSCE_C_DEFAULT = 0
        ; #nSCE_C_COMMENTLINE = 2
        ; #nSCE_C_COMMENTDOC = 3
        ; #nSCE_C_NUMBER = 4
        ; #nSCE_C_WORD = 5
        ; #nSCE_C_STRING = 6
        ; #nSCE_C_CHARACTER = 7
        ; #nSCE_C_UUID = 8
        ; #nSCE_C_PREPROCESSOR = 9
        ; #nSCE_C_OPERATOR = 10
        ; #nSCE_C_IDENTIFIER = 11                   ;http://www.math-cs.gordon.edu/courses/cs323/COBOL/cobol.html
        ; #nSCE_C_WORD2 = 16
        ;
        ; *** For the style, check http://www.scintilla.org/ScintillaDoc.html#SCI_SETSTYLING
        ; like if we want bold, italic, ...
        ;
        ; Nothing happens with the following
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_WORD, RGB(0, 255, 255))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_WORD, RGB(0, 255, 255))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_WORD2, RGB(0, 255, 255))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_WORD2, RGB(0, 255, 255))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_UUID, RGB(0, 255, 255))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_UUID, RGB(0, 255, 255))
        
        
        ; The 2 following lines are MANDATORY
        ; if not, the background will not be used
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_DEFAULT, RGB(106, 184, 37))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_DEFAULT, RGB(32, 32, 32))
        ; 
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_IDENTIFIER, RGB(106, 184, 37)) ;RGB(64, 255, 255))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_IDENTIFIER, RGB(32, 32, 32))
        ;         
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_STRING,     RGB(237, 157, 19))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_STRING,     RGB(32, 32, 32))
        ;         
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_NUMBER,  RGB(54, 119, 169))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_NUMBER,  RGB(32, 32, 32))
        
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_COMMENTLINE, RGB(153, 153, 153))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_COMMENTLINE, RGB(32, 32, 32))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_COMMENTDOC, RGB(153, 153, 153))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_COMMENTDOC, RGB(32, 32, 32))
        ;-- COMMENT LINE IN ITALIC
        ; cf goscintilla.pbi line 2160
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETITALIC, #nSCE_C_COMMENTLINE, #True)
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETITALIC, #nSCE_C_COMMENTDOC, #True)
        
        ; nothing happens With the 2 following line
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_CHARACTER, RGB(208, 208, 208))
        ;         ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_CHARACTER, RGB(32, 32, 32))
        
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSCE_C_OPERATOR, RGB(64, 255, 255));RGB(208, 208, 208))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSCE_C_OPERATOR, RGB(32, 32, 32))
        
        ScintillaSendMessage(scintillaId, #nSCI_SETKEYWORDS,  #nSCLEX_COBOL,   UTF8(KeyWords))
        ;     ScintillaSendMessage(scintillaId, #nSCI_SETKEYWORDS,  0,               *UTF8)           ;define keywords
    Else
        ScintillaSendMessage(scintillaId, #nSCI_SETLEXER, #nSCLEX_NULL, 0)          ;no lexer
        ScintillaSendMessage(scintillaId, #nSCI_STARTSTYLING, 0, 31)                ;set start of styling to pos 0
        iLen = ScintillaSendMessage(scintillaId, #nSCI_GETTEXTLENGTH, 0, 0)         ;get len of document
        ScintillaSendMessage(scintillaId, #nSCI_SETSTYLING, iLen, #nSTYLE_DEFAULT)  ;set style of entire document
                                                                                    ;-- FONT COLOR (FORE & BACK) FOR THE TEXT
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETFORE, #nSTYLE_DEFAULT, RGB(106, 184, 37))
        ScintillaSendMessage(scintillaId, #nSCI_STYLESETBACK, #nSTYLE_DEFAULT, RGB(32, 32, 32))
    EndIf
EndProcedure

;-**** RESIZE IDE
Procedure resizeIDE()
    Protected.i width  = WindowWidth(#MAIN_WINDOW)
    Protected.i height = WindowHeight(#MAIN_WINDOW)
    If width < 640 : width = 640 : ResizeWindow(#MAIN_WINDOW, #PB_Ignore, #PB_Ignore, width, #PB_Ignore) : EndIf
    If height < 480 : height = 480 : ResizeWindow(#MAIN_WINDOW, #PB_Ignore, #PB_Ignore, #PB_Ignore, height) : EndIf
    ;     ResizeGadget(#EDITOR, #PB_Ignore, #PB_Ignore, width - 10, height - (GadgetHeight(#MAIN_MENU) + GadgetHeight(#TOOL_BAR)))
    ; adding +2 to the width, to remove the 2 white lines on the right
    ResizeGadget(#EDITOR, #PB_Ignore, #PB_Ignore, width + 2, height - ToolBarHeight(#TOOL_BAR) - StatusBarHeight(#STATUS_BAR) - MenuHeight() - 20)
EndProcedure

;-**** GET CHAR HEIGHT
Procedure GetCharHeight(fontID.i)
    Protected.i fontHeight
    Protected.i tmpImage = CreateImage(#PB_Any, 40, 40)
    
    StartDrawing(ImageOutput(tmpImage))
    DrawingFont(FontID(fontID))
    fontHeight = TextHeight("M")
    ;** to test
    ;         DrawText(0,0,"M", RGB(0,0,0), RGB(255,255,255))
    ;         DrawText(0,20,"W", RGB(255,255,255), RGB(255,0,0))
    ;         SaveImage(tmpImage, "CharHeight.bmp")
    ;**********
    StopDrawing()
    
    FreeImage(tmpImage)
    ProcedureReturn fontHeight
EndProcedure

;-**** GENERATE RULER
Procedure GenerateRuler()
    ;TODO:  Create a ruler that start at col 7 and the colum numbers will
    ;       be automatically filled.
    ;       Automatic system with the choice of the step
    
    ; Positions	Field	                Description
    ; 1-6	    Column Numbers	        Reserved For line numbers.
    ; 7	        Indicator	            It can have Asterisk (*) indicating comments, 
    ;                                   Hyphen (-) indicating continuation 
    ;                                   Slash ( / ) indicating form feed.
    ; 8-11	    Area A	                All COBOL divisions, sections, paragraphs And some special entries must begin in Area A.
    ; 12-72	    Area B	                All COBOL statements must begin in area B.
    ; 73-80	    Identification Area	    It can be used As needed by the programmer.
    
    ; for a help see: http://publib.boulder.ibm.com/iseries/v5r1/ic2924/books/c092539202.htm#ToC_54
    
    ;     Protected.s ruler = "----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8"
    ;     Protected.s ruler = "nnnnnn*AAAAB.......2.........3.........4.........5.........6.........7.B--------"
    ;     Protected.s ruler = "      *A-1-B--+----2----+----3----+----4----+----5----+----6----+----7--I-+----8"
    Protected *this.CS_CANVAS_RULER
    
    Protected.s ruler = "      *A-1-B--+----2----+----3----+----4----+----5----+----6----+----7--*******8"
    Protected.i drawCharPosY, addCaretPosY = 0
    
    CanvasGadget(#EDITOR_CANVAS_RULER, 0, ToolBarHeight(#TOOL_BAR), DESKTOP_WIDTH, 20)
    
    ;Allocate memory for our canvas ruler structure
    *this = AllocateMemory(SizeOf(CS_CANVAS_RULER))
    If *this
        With *this
            \oneCharWidth    = ONE_CHAR_WIDTH
            \oneCharHeight   = GetCharHeight(#EDITOR_FONT_ID)
            \marginWidth     = MARGIN_WIDTH
            \rulerTextLength = Len(ruler)
            \rulerWidth      = Len(ruler) * ONE_CHAR_WIDTH
            \rulerHeight     = GadgetHeight(#EDITOR_CANVAS_RULER)
        EndWith
        
        If CreateImage(#EDITOR_IMG_RULER, *this\rulerWidth, *this\rulerHeight) And StartDrawing(ImageOutput(#EDITOR_IMG_RULER))
            ;             Debug "charWidth: " + Str(*this\oneCharWidth)
            ;             Debug "charHeight: " + Str(*this\oneCharHeight)
            ;             Debug "rulerHeight: " + Str(*this\rulerHeight)
            drawCharPosY = (*this\rulerHeight - *this\oneCharHeight) / 2
            
            ; If the height of the char is bigger or equal
            ; need to remove to pixel from the top
            If *this\oneCharHeight >= *this\rulerHeight
                drawCharPosY = -2
                addCaretPosY = -1
            EndIf
            *this\drawCharPosY = drawCharPosY
            *this\addCaretPosY = addCaretPosY
            
            ; Start to draw the ruler
            DrawingMode(#PB_2DDrawing_Transparent)
            Box(0, 0, *this\rulerWidth, *this\rulerHeight, RGB(64, 64, 64))
            DrawingFont(FontID(#EDITOR_FONT_ID))
            ;         DrawText(0, 1, ruler, RGB(106, 184, 37), RGB(64, 64, 64))
            ;             DrawText(0, 1, ruler, RGB(128, 128, 128))
            DrawText(0, drawCharPosY, ruler, RGB(128, 128, 128))
            
            StopDrawing()
            ; For the callback, he can use the ruler now
            RULER_ON = #True
        EndIf
        ;** IF there is map, list, array in the structure
        ;** SHOULD initialize structure
        ; InitializeStructure(*this, CS_CANVAS_RULER)
        ;Record a pointer to our canvas ruler structure
        SetGadgetData(#EDITOR_CANVAS_RULER, *this)
    Else
        ClearStructure(*this, CS_CANVAS_RULER)
        FreeMemory(*this)
    EndIf
    
EndProcedure

;-**** EDITOR CALLBACK
Procedure editorCallBack(idEditor, *scinotify.SCNotification)
    ; ### IMPLEMENTING ###
    ; ###    SYNTAX    ###
    ; ###   STYLING    ###
    ;
    ; check:
    ; http://www.scintilla.org/ScintillaUsage.html
    ;
    ; ### SCNOFITY ###
    ;
    ; check:
    ; https://metacpan.org/pod/Win32::GUI::Scintilla
    ; http://www.scintilla.org/ScintillaDoc.html#Notifications
    ; https://www.garybeene.com/code/gbsnippets_gbs_00675.htm
    Protected.i currentPos, currentColumn, currentLine
    Protected.i currentZoom, textHeight
    Protected *this.CS_CANVAS_RULER
    
    ; Get current position of the cursor to display current line and current column
    currentPos    = ScintillaSendMessage(#EDITOR, #nSCI_GETCURRENTPOS, 0, 0)
    currentColumn = ScintillaSendMessage(#EDITOR, #nSCI_GETCOLUMN, currentPos) + 1
    currentLine   = ScintillaSendMessage(#EDITOR, #nSCI_LINEFROMPOSITION, currentPos) + 1
    StatusBarText(#STATUS_BAR, 0, "Line: "+ Str(currentLine) + "  Column: " + Str(currentColumn), #PB_StatusBar_Center)
    ;     StatusBarText(#STATUS_BAR, 2, "Line Count: " + Str(ScintillaSendMessage(#EDITOR, #nSCI_GETLINECOUNT)))
    
    currentZoom = ScintillaSendMessage(#EDITOR, #nSCI_GETZOOM)
    textHeight  = ScintillaSendMessage(#EDITOR, #nSCI_TEXTHEIGHT, 0)
    
    ; *** Need to be sure the ruler has been created ***
    If RULER_ON
        *this = GetGadgetData(#EDITOR_CANVAS_RULER)
        Select *scinotify\nmhdr\code
                ;         Case #nSCN_STYLENEEDED                ;works only when SCI_SETLEXER(SCLEX_CONTAINER) is used
            Case #nSCN_ZOOM
                ; Get the current char width after zooming to calculate the new ruler
                *this\oneCharWidth = ScintillaSendMessage(#EDITOR, #nSCI_TEXTWIDTH, #nSTYLE_DEFAULT, UTF8("W"))
        EndSelect
        
        ;         StatusBarText(#STATUS_BAR, 2, 
        ;         "Z/RTLn/Th/CHw: " + Str(currentZoom) + "/" + Str(*this\rulerTextLength) + "/" + Str(textHeight) + "/" + Str(*this\oneCharWidth))
        
        If StartDrawing(CanvasOutput(#EDITOR_CANVAS_RULER))
            ; Background color
            Box(0, 0, DESKTOP_WIDTH, *this\rulerWidth, RGB(64, 64, 64))
            
            ; Separation
            Line(*this\marginWidth + (#EXTRA_MARGIN_WIDTH - 1), 
                 #DRAW_AT_POS_Y, 1, 
                 *this\rulerHeight - 3, 
                 RGB(32, 32, 32))   ;same as background color for editor
            
            ; Surround
            LineXY(0, 0, DESKTOP_WIDTH, 0, RGB(160,160,160)) 
            LineXY(0, 0, 0, *this\rulerHeight, RGB(160,160,160)) 
            
            LineXY(1, 1, DESKTOP_WIDTH, 1, RGB(105,105,105)) 
            LineXY(1, 1, 1, *this\rulerHeight - 1, RGB(105,105,105)) 
            LineXY(1, *this\rulerHeight - 1, DESKTOP_WIDTH, *this\rulerHeight - 1, RGB(105,105,105)) 
            
            ; Draw our ruler
            DrawImage(ImageID(#EDITOR_IMG_RULER), *this\marginWidth + #EXTRA_MARGIN_WIDTH, #DRAW_AT_POS_Y, *this\oneCharWidth * *this\rulerTextLength, *this\rulerHeight)
            
            ; Draw the position of the cursor on the ruler
            ;             DrawingMode(#PB_2DDrawing_Default)
            ;             DrawingMode(#PB_2DDrawing_Outlined)
            ;             DrawingMode(#PB_2DDrawing_XOr)
            DrawingMode(#PB_2DDrawing_AlphaBlend) ; with RGBA and alpha channel of 127
                                                  ;             DrawingMode(#PB_2DDrawing_AlphaClip) ; same as AlphaBlend
            
            ; Where to draw the caret?
            x = (currentColumn - 1) * *this\oneCharWidth + *this\marginWidth + #EXTRA_MARGIN_WIDTH
            ; Adding one pixel to be centered verticaly
            y = #DRAW_AT_POS_Y + *this\addCaretPosY
            
            ; Draw the caret
            ; For Outlined or Xor
            ;             Box(x + 3, y + 3, *this\oneCharWidth, 15, RGB(255, 255, 0))
            ;             Box(x + 3, y + 2, *this\oneCharWidth, 17, RGB(255, 255, 0))
            
            ;For drawing mode default
            ;             Box(x + 3, y + 15, *this\oneCharWidth, 4, RGB(255, 255, 0))
            ;             Box(x + 3, y + 16, *this\oneCharWidth, 3, RGB(255, 255, 0))
            ;             Box(x + 3, y + 16, *this\oneCharWidth, 2, RGB(50, 255, 50))
            
            ; For Alpha
            Box(x, y + 1, *this\oneCharWidth, *this\oneCharHeight, RGBA(106, 184, 37, 128));RGBA(0, 200, 255, 127))
            
            StopDrawing()
        EndIf
    EndIf
EndProcedure

;-**** INIT EDITOR
Procedure initEditor()
    If InitScintilla(#SCINTILLA_DLL)
        ScintillaGadget(#EDITOR,
                        0,
                        ToolBarHeight(#TOOL_BAR) + 20, 
                        ; adding +2, to remove the 2 white lines on the right
        WindowWidth(#MAIN_WINDOW) + 2,
WindowHeight(#MAIN_WINDOW) - ToolBarHeight(#TOOL_BAR) - StatusBarHeight(#STATUS_BAR) - MenuHeight() - 20,
@editorCallBack())
        
        ;- Required for the tab key to be correctly used when the Scintilla control has the focus.
        RemoveKeyboardShortcut(#MAIN_WINDOW, #PB_Shortcut_Tab)
        
        ;- Add the cobol margins
        ; The first one is to separate the gutter to the source
        AddElement(Margin())
        Margin()\pos = 1
        Margin()\color = RGB(50, 50, 50)
        
        ;- Cobol mandatories margins
        AddElement(Margin())
        Margin()\pos = 8
        Margin()\color = RGB(150,150,150)
        
        AddElement(Margin())
        Margin()\pos = 12
        Margin()\color = RGB(150,150,150)
        
        AddElement(Margin())
        Margin()\pos = 73
        Margin()\color = RGB(255,0,0)
        
        AddElement(Margin())
        Margin()\pos = 80
        Margin()\color = RGB(255,0,0)
        
        ;-- SET UTF-8 CODEPAGE
        ScintillaSendMessage(#EDITOR, #nSCI_SETCODEPAGE, #nSC_CP_UTF8, 0)
        ;-- SET LEXER
        ;ScintillaSendMessage(#EDITOR, #nSCI_SETLEXER, #nSCLEX_CONTAINER)
        ;ScintillaSendMessage(#EDITOR, #nSCI_SETLEXER, #nSCLEX_COBOL)
        
        ;-- SHOW/HIDE SCROLLBARS
        ScintillaSendMessage(#EDITOR, #nSCI_SETVSCROLLBAR, #True)
        ScintillaSendMessage(#EDITOR, #nSCI_SETHSCROLLBAR, #False)
        
        ;-- SET DEFAULT FONT
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETFONT, #nSTYLE_DEFAULT, UTF8(#FONT_NAME_EDITOR))
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETSIZE, #nSTYLE_DEFAULT, #FONT_SIZE_EDITOR)
        ScintillaSendMessage(#EDITOR, #nSCI_STYLECLEARALL)
        ONE_CHAR_WIDTH = ScintillaSendMessage(#EDITOR, #nSCI_TEXTWIDTH, #nSTYLE_DEFAULT, UTF8("W"))
        
        ;-- SET TAB TO 4 SPACES
        ScintillaSendMessage(#EDITOR, #nSCI_SETTABWIDTH, 4)
        ScintillaSendMessage(#EDITOR, #nSCI_SETUSETABS, #False)
        
        ;********* UNFORTUNATELY, following lines are just a request I saw
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETSPECIFICTABCOUNT, 3)
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETSPECIFICTAB, 7)
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETSPECIFICTAB, 14)
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETSPECIFICTAB, 50)
        
        ;-- BACKGROUND COLOR FOR THE EDITOR
        ;         ScintillaSendMessage(#EDITOR, #nSCI_STYLESETBACK, #nSTYLE_DEFAULT, RGB(32, 32, 32))
        
        ;-- FONT COLOR (FORE & BACK) FOR THE TEXT
        ;         ScintillaSendMessage(#EDITOR, #nSCI_STYLESETBACK, 0, RGB(32, 32, 32))
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETBACK, #nSTYLE_DEFAULT, RGB(32, 32, 32))
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETFORE, #nSTYLE_DEFAULT, RGB(106, 184, 37))
        
        ;-- SET CURSOR SHAPE AND COLOR
        ScintillaSendMessage(#EDITOR, #nSCI_SETCARETSTYLE, #nCARETSTYLE_BLOCK)
        ScintillaSendMessage(#EDITOR, #nSCI_SETCARETFORE, RGB(255, 254, 0)) ;RGB(0, 255, 65))
                                                                            ;ScintillaSendMessage(#EDITOR, #nSCI_SETCARETWIDTH, 3); Largeur du curseur si on n'utilise pas le type CARETSTYLE_BLOCK
        
        ;-- ADD MULTI VERTICAL EDGE LINE
        ForEach Margin()
            ScintillaSendMessage(#EDITOR, #nSCI_MULTIEDGEADDLINE, Margin()\pos - 1, Margin()\color)
        Next
        ScintillaSendMessage(#EDITOR, #nSCI_SETEDGEMODE, #nEDGE_MULTILINE, #Null)
        
        ;-- CURRENT LINE BACKGROUND COLOR
        ScintillaSendMessage(#EDITOR, #nSCI_SETCARETLINEBACK, RGB(64, 64, 64))
        ScintillaSendMessage(#EDITOR, #nSCI_SETCARETLINEVISIBLE, #True)
        
        ;-- MARGIN LINE NUMBER WIDTH, COLOR & FONT
        ; Set LineNumber
        ; This returns the pixel width of a string drawn in the given style which can be used, for example, 
        ; to decide how wide to make the line number margin in order to display a given number of numerals.
        width = ScintillaSendMessage(#EDITOR, #nSCI_TEXTWIDTH, #nSTYLE_LINENUMBER, UTF8("_99999"))
        ; Margin index is 0 here (max is 3)
        ; it doesn't need a mask because it is not a symbol margin, it is a line number margin
        ScintillaSendMessage(#EDITOR, #nSCI_SETMARGINTYPEN, 0, #nSC_MARGIN_NUMBER)
        ScintillaSendMessage(#EDITOR, #nSCI_SETMARGINMASKN, 0, #nSC_MASK_FOLDERS)
        ScintillaSendMessage(#EDITOR, #nSCI_SETMARGINWIDTHN, 0, width)
        
        ; Linenumber Color and font
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETFORE, #nSTYLE_LINENUMBER, RGB(200, 200, 200))
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETBACK, #nSTYLE_LINENUMBER, RGB(48, 48, 48))
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETFONT, #nSTYLE_LINENUMBER, UTF8(#FONT_NAME_EDITOR))
        ScintillaSendMessage(#EDITOR, #nSCI_STYLESETSIZE, #nSTYLE_LINENUMBER, #FONT_SIZE_LINE_NUMBER)
        ; Set Margin backcolor
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETMARGINBACKN, 0, RGB(64, 64, 64))
        ;         ScintillaSendMessage(#EDITOR, #nSCI_MARKERENABLEHIGHLIGHT, #True)
        
        ;-- LINE PADDING TOP & BOTTOM
        ; "line_padding_bottom": 5,
        ; "line_padding_top": 5,
        ScintillaSendMessage(#EDITOR, #nSCI_SETEXTRAASCENT, 4)      ;top
        ScintillaSendMessage(#EDITOR, #nSCI_SETEXTRADESCENT, 3)     ;bottom
        
        ; The mouse was clicked inside a margin that was marked as sensitive (see SCI_SETMARGINSENSITIVEN). 
        ; This can be used to perform folding or to place breakpoints. The following SCNotification fields are used:
        ;   Field	Usage
        ;       modifiers	The appropriate combination of SCI_SHIFT, SCI_CTRL And SCI_ALT To indicate the keys that were held down at the time of the margin click.
        ;       position	The position of the start of the line in the document that corresponds To the margin click.
        ;       margin	    The margin number that was clicked.
        ScintillaSendMessage(#EDITOR, #nSCI_SETMARGINSENSITIVEN, 0, #True)
        
        ;-- SET SELECTION FORE & BACK COLOR
        ; You can choose to override the default selection colouring with these two messages. 
        ; The colour you provide is used if you set useSelection*Colour to true. 
        ; If it is set to false, the default styled colouring is used and the fore or back argument has no effect.
        ScintillaSendMessage(#EDITOR, #nSCI_SETSELFORE, #True, RGB(255,255,255))
        ScintillaSendMessage(#EDITOR, #nSCI_SETSELBACK, #True, RGB(0, 111, 175))
        
        ;-- ENABLE MULTI CURSOR EDITING
        ; from http://www.purebasic.fr/english/viewtopic.php?p=455672#p455672
        ; ALT+mouse selection : create rectangle selection
        ; CTRL+mouse selection : create multi ranges selection
        ; CTRL+mouse click : create additional cursor
        ; Select rectangle range by holding down the ALT key while dragging with the mouse
        ; The key used to indicate that a rectangular selection should be created when combined with a mouse drag can be set.
        ; The three possible values are SCMOD_CTRL=2 (default), SCMOD_ALT=4 or SCMOD_SUPER=8.
        ; Since SCMOD_ALT is often already used by a window manager, 
        ; the window manager may need configuring to allow this choice.
        ; SCMOD_SUPER is often a system dependent modifier key such as
        ; the Left Windows key on a Windows keyboard or the Command key on a Mac.
        ScintillaSendMessage(#EDITOR, #nSCI_SETRECTANGULARSELECTIONMODIFIER, #nSCMOD_ALT)
        
        ;-- ENABLE MULTI SELECTION
        ; Enable multiple selection. It is possible to select multiple ranges by holding down the Ctrl key while dragging with the mouse.
        ScintillaSendMessage(#EDITOR, #nSCI_SETMULTIPLESELECTION, #True)
        ; Set Additional Caret and Selection color (when multiple selection is enabled)
        ScintillaSendMessage(#EDITOR, #nSCI_SETADDITIONALCARETFORE, RGB(100, 100, 100)) ;RGB(106, 184, 37)); RGB(157, 64, 41))
        ScintillaSendMessage(#EDITOR, #nSCI_SETADDITIONALCARETSBLINK, #True)
        ; Background color when selected with CTRL        
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETADDITIONALSELBACK, RGB(255, 160, 136))
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETADDITIONALSELFORE, RGB(200, 200, 200))
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETADDITIONALSELALPHA, 100)
        
        ; When pasting into multiple selections, the pasted text can go into just the main selection with
        ; SC_MULTIPASTE_ONCE=0 or into each selection with SC_MULTIPASTE_EACH=1. SC_MULTIPASTE_ONCE is the default.
        ScintillaSendMessage(#EDITOR, #nSCI_SETMULTIPASTE, #nSC_MULTIPASTE_EACH)
        ; Whether typing, new line, cursor left/right/up/down, backspace, delete, home, and end work with multiple selections simultaneously.
        ; Also allows selection and word and line deletion commands.
        ScintillaSendMessage(#EDITOR, #nSCI_SETADDITIONALSELECTIONTYPING, #True)
        
        ; Allow cursor and rect selection to move beyond end of line
        ;         ScintillaSendMessage(#EDITOR, #nSCI_SETVIRTUALSPACEOPTIONS, #nSCVS_RECTANGULARSELECTION | #nSCVS_USERACCESSIBLE)
        
        
        syntaxHighLighting(#EDITOR)
        
        SetActiveGadget(#EDITOR)
        ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
EndProcedure

;-**** QUIT PROGRAM
Procedure.i QuitProgram()
    If MessageRequester(#APP_NAME, "Do you really want to quit ?", #PB_MessageRequester_Info | #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
        ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
EndProcedure

;-**** MAIN PROGRAM
Procedure Main()
    Protected.i Event, Result, hightlightEnable, Quit = #False
    
    ExamineDesktops()
    DESKTOP_WIDTH = DesktopWidth(0)
    
    ;         If OpenWindow(#MAIN_WINDOW, 0, 0, 880, 600, "BCoIDE", #PB_Window_Maximize | #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)
    If OpenWindow(#MAIN_WINDOW, 0, 0, 880, 600, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)
        ;Enables a smart way to refresh the window to reduce the flickering when resizing the window
        SmartWindowRefresh(#MAIN_WINDOW, #True)
        
        ;-Load the MAIN FONT
        LoadFont(#EDITOR_FONT_ID, #FONT_NAME_EDITOR, #FONT_SIZE_EDITOR)
        
        ;TODO : Load preference for colors like Sublime Text
        CreateMenu(#MAIN_MENU, WindowID(#MAIN_WINDOW))
        MenuTitle("File")
        MenuItem(#MENU_FILE_NEW, "New" + Chr(9) + "Ctrl+N")
        MenuItem(#MENU_FILE_OPEN, "Open"+ Chr(9) + "Ctrl+O")
        MenuItem(#MENU_FILE_SAVE, "Save")
        MenuItem(#MENU_FILE_SAVE_AS, "Save as")
        MenuBar()
        MenuItem(#MENU_FILE_QUIT, "Exit")
        MenuTitle("Edit")
        MenuItem(#MENU_EDIT_UNDO, "Undo")
        MenuItem(#MENU_EDIT_REDO, "Redo")
        MenuTitle("HighLight")
        MenuItem(#MENU_HIGHLIGHT, "Enable")
        SetMenuItemState(#MAIN_MENU, #MENU_HIGHLIGHT, #True)
        MenuTitle("About")
        
        CreateToolBar(#TOOL_BAR, WindowID(#MAIN_WINDOW))
        ;             ToolBarImageButton(0, LoadImage(0, #IMG + "document-new.png"))
        ;             ToolBarImageButton(1, LoadImage(0, #IMG + "document-open.png"))
        ;             ToolBarSeparator()
        ;             ToolBarImageButton(2, LoadImage(0, #IMG + "document-save.png"))
        
        CreateStatusBar(#STATUS_BAR, WindowID(#MAIN_WINDOW))
        AddStatusBarField(220)
        AddStatusBarField(60)
        AddStatusBarField(300)
        ; for the info of the executable (compile count, ...)
        AddStatusBarField(#PB_Ignore)
        
        StatusBarText(#STATUS_BAR, 0, "")
        StatusBarText(#STATUS_BAR, 1, "")
        StatusBarText(#STATUS_BAR, 2, "")
        StatusBarText(#STATUS_BAR, 3, "cc#" + Str(#PB_Editor_CompileCount) + "-bc#" + Str(#PB_Editor_BuildCount ), #PB_StatusBar_Right)
        
        ;         If ListViewGadget(#LIST_VIEW,
        ;                           0,
        ;                           ToolBarHeight(#TOOL_BAR), 
        ;                           200,
        ;                           WindowHeight(#MAIN_WINDOW) - ToolBarHeight(#TOOL_BAR) - StatusBarHeight(#STATUS_BAR) - MenuHeight())
        ;         EndIf
        
        ;>>> MAIN <<<
        If initEditor()
            ; Get total margin width by adding all of them
            ; MARGIN_WIDTH get the position to start for the cursor in the ruler
            MARGIN_WIDTH = 0
            For i = 0 To 4 : MARGIN_WIDTH + ScintillaSendMessage(#EDITOR, #nSCI_GETMARGINWIDTHN, i) : Next
            GenerateRuler()
            
            ;             SplitterGadget(#SPLIT_LIST_EDITOR,
            ;                            0,
            ;                            0,
            ;                            GadgetHeight(#LIST_VIEW) + GadgetHeight(0),
            ;                            WindowHeight(#MAIN_WINDOW) - ToolBarHeight(#TOOL_BAR) - StatusBarHeight(#STATUS_BAR) - MenuHeight(),
            ;                            #LIST_VIEW, 0,
            ;                            #PB_Splitter_Separator | #PB_Splitter_Vertical)
            
            BindEvent(#PB_Event_SizeWindow, @resizeIDE())
            
            AddKeyboardShortcut(#MAIN_WINDOW, #PB_Shortcut_Control | #PB_Shortcut_O, #MENU_FILE_OPEN)
            Repeat
                Event = WaitWindowEvent()
                
                Select Event
                    Case #PB_Event_CloseWindow
                        Quit = QuitProgram()
                        
                    Case #PB_Event_Menu
                        Select EventMenu()
                            Case #MENU_FILE_OPEN
                                LoadSrcFile(#EDITOR)
                            Case #MENU_FILE_QUIT
                                Quit = QuitProgram()
                            Case #MENU_HIGHLIGHT
                                hightlightEnable = 1 - GetMenuItemState(#MAIN_MENU, #MENU_HIGHLIGHT)
                                SetMenuItemState(#MAIN_MENU, #MENU_HIGHLIGHT, hightlightEnable)
                                syntaxHighLighting(#EDITOR, hightlightEnable)
                        EndSelect
                EndSelect
            Until Quit
        Else
            MessageRequester(#APP_NAME+ " ERROR", "Whoops!!! Looks like something went wrong with the editor.")
            End
        EndIf
    Else
        MessageRequester(#APP_NAME + " ERROR", "Whoops!!! Looks like something went wrong with the application.")
        End
    EndIf
EndProcedure

;-**** CALLING PROGRAM
Main()
