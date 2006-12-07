int     maybeDefinition(char * s, size_t n);
int     existsDefinition(char * s);
void    newDefinition(char *name, char *opt_param, char *def, int params);
void    renewDefinition(char * name, char *opt_param, char * def, int params);
char *  expandDefinition(int thedef);

int     maybeEnvironment(char * s, size_t n);
int     existsEnvironment(char * s);
void    newEnvironment(char *name, char *opt_param, char *begdef, char *enddef, int params);
void    renewEnvironment(char *name, char *opt_param, char *begdef, char *enddef, int params);
char *  expandEnvironment(int thedef, int starting);

void    newTheorem(char *name, char *caption, char *numbered_like, char *within);
int     existsTheorem(char * s);
char    *expandTheorem(int i, char *option);
void    resetTheoremCounter(char *unit);
