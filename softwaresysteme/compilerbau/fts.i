%{

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "fts.tab.h"

static const char *ABBREV_LIST[] = {
    ['a'] = "artist",
    ['b'] = "album",
    ['c'] = "album_artist",
    ['d'] = "duration",
    ['g'] = "genre",
    ['n'] = "name",
    ['p'] = "performer",
    ['r'] = "track",
    ['s'] = "disc",
    ['y'] = "date",
    ['t'] = "title",
    ['u'] = "uri",
    ['~'] = ""
};

/* Make an abbreviated tag to a full one, leave full one. */
static char *fix_tag() {
    size_t len = strlen(yytext);
    char *tag = NULL;

    if (len == 2 && yytext[1] == ':') {
        int c = *yytext;
        if (c < '~') {
            tag = (char *)ABBREV_LIST[c];
        }
    } 

    if(tag == NULL) {
        tag = yytext;
    }

    return tag;
}

%}

/* General options */
%option noyywrap
%option bison-bridge

/* Two states for date: and quoted strings */
%x QUOTED_STRING EXPECT_DATE

/* Utility patterns */
letter [a-zA-Z]
num [0-9]
specelem [^ \t"*():+|!\n]

%%

"(" {
    return PARAN_OPEN;
}

")" {
    return PARAN_CLOSE;
}

"\"" {
    BEGIN(QUOTED_STRING);
}

<QUOTED_STRING>[^"]* {
    yylval->spec = yytext;
    return SPEC;
}

<QUOTED_STRING>"\"" {
    BEGIN(INITIAL);
}

"+" {
    return OPER_AND;
}

"|" {
    return OPER_OR;
}

"!" {
    return UNARY_OPER_NOT;
}

(d\:|date\:) {
    BEGIN(EXPECT_DATE);
    yylval->tag = fix_tag();
    return TAG;
}

{letter}+\:  {
    yylval->tag = fix_tag();
    return TAG;
}

<EXPECT_DATE>({num}+|{num}+-{num}+) {
    BEGIN(INITIAL);
    
    /* Parse the date range. */
    char *is_range = strchr(yytext, '-');
    if(!is_range) {
        int val = strtol(yytext, NULL, 10);
        yylval->range.begin = yylval->range.end = val;
    } else {
        yylval->range.begin = strtol(yytext, NULL, 10);
        yylval->range.end = strtol(&is_range[1], NULL, 10);
    }

    return DATE_SPEC;
}

<EXPECT_DATE> { 
    printf("FFFFUUUU\n");
}

"*" {
    return MATCH_ALL;
}

{specelem}+\* {
    yylval->spec = yytext;
    return SPEC;
}

{specelem}+ {
    yylval->spec = yytext;
    return SPEC;
}

[ \t\n\r] {
    /* Ignore whitespace */ 
}

%%
