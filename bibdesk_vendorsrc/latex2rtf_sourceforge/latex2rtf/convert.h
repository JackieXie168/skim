#define MODE_INTERNAL_VERTICAL     1
#define MODE_HORIZONTAL            2
#define MODE_RESTRICTED_HORIZONTAL 3
#define MODE_MATH                  4
#define MODE_DISPLAYMATH           5
#define MODE_VERTICAL              6

extern char TexModeName[7][25];

void SetTexMode(int mode);
int  GetTexMode(void);

void ConvertString(char *string);
void ConvertAllttString(char *s);
void Convert();

