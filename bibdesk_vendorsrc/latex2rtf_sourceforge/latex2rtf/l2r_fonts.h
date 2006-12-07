/* $Id: l2r_fonts.h,v 1.16 2004/10/03 22:35:25 prahl Exp $ */

#define F_FAMILY_ROMAN          1
#define F_FAMILY_ROMAN_1        2
#define F_FAMILY_ROMAN_2        3
#define F_FAMILY_ROMAN_3        4
#define F_FAMILY_ROMAN_4        17
#define F_FAMILY_SANSSERIF      5
#define F_FAMILY_SANSSERIF_1    6
#define F_FAMILY_SANSSERIF_2    7
#define F_FAMILY_SANSSERIF_3    8
#define F_FAMILY_SANSSERIF_4    18
#define F_FAMILY_TYPEWRITER     9
#define F_FAMILY_TYPEWRITER_1   10
#define F_FAMILY_TYPEWRITER_2   11
#define F_FAMILY_TYPEWRITER_3   12
#define F_FAMILY_TYPEWRITER_4   19
#define F_FAMILY_CALLIGRAPHIC   13
#define F_FAMILY_CALLIGRAPHIC_1 14
#define F_FAMILY_CALLIGRAPHIC_2 15
#define F_FAMILY_CALLIGRAPHIC_3 16

#define F_SHAPE_SLANTED      1
#define F_SHAPE_SLANTED_1    2
#define F_SHAPE_SLANTED_2    3
#define F_SHAPE_SLANTED_3    4
#define F_SHAPE_SLANTED_4    17
#define F_SHAPE_ITALIC       5
#define F_SHAPE_ITALIC_1     6
#define F_SHAPE_ITALIC_2     7
#define F_SHAPE_ITALIC_3     8
#define F_SHAPE_ITALIC_4     18
#define F_SHAPE_CAPS         9
#define F_SHAPE_CAPS_1       10
#define F_SHAPE_CAPS_2       11
#define F_SHAPE_CAPS_3       12
#define F_SHAPE_CAPS_4       19
#define F_SHAPE_UPRIGHT      13
#define F_SHAPE_UPRIGHT_1    14
#define F_SHAPE_UPRIGHT_2    15
#define F_SHAPE_UPRIGHT_3    16
#define F_SHAPE_MATH_UPRIGHT 17

#define F_SERIES_MEDIUM      1
#define F_SERIES_MEDIUM_1    2
#define F_SERIES_MEDIUM_2    3
#define F_SERIES_MEDIUM_3    4
#define F_SERIES_BOLD        5
#define F_SERIES_BOLD_1      6
#define F_SERIES_BOLD_2      7
#define F_SERIES_BOLD_3      8
#define F_SERIES_BOLD_4      9

#define F_TEXT_NORMAL      1
#define F_TEXT_NORMAL_1    2
#define F_TEXT_NORMAL_2    3
#define F_TEXT_NORMAL_3    4

#define F_EMPHASIZE_1      2
#define F_EMPHASIZE_2      3
#define F_EMPHASIZE_3      4

#define F_SMALLER           -1
#define F_LARGER            -2

void	InitializeDocumentFont(int family, int size, int shape, int series);

void	CmdFontFamily(int code);
int		CurrentFontFamily(void);
int		DefaultFontFamily(void);

void	CmdFontShape(int code);
int		CurrentFontShape(void);
int		DefaultFontShape(void);

void	CmdFontSeries(int code);
int 	CurrentFontSeries(void);
int 	DefaultFontSeries(void);

void	CmdFontSize(int code);
int		CurrentFontSize(void);
int		DefaultFontSize(void);
int 	CurrentCyrillicFontFamily(void);
int 	CurrentLatin1FontFamily(void);
int 	CurrentLatin2FontFamily(void);

void	CmdEmphasize(int code);
void	CmdUnderline(int code);
void	CmdTextNormal(int code);

int 	TexFontNumber(char *Fname);
int 	RtfFontNumber(char *Fname);

void	PushFontSettings(void);
void	PopFontSettings(void);
void  	MonitorFontChanges(char *text);
