parser grammar LamaParser;

@header {
package com.soarex.truffle.lama.parser;
}

options {
    tokenVocab=LamaLexer;
}

program
    : scopeExpression EOF
    ;

scopeExpression
    : defs+=definition* expr=expression?
    ;

definition
    : variableDefinition
    | functionDefinition
    ;

variableDefinition
    : VAR variableDefinitionSequence SEMICOLON
    ;

variableDefinitionSequence
    : defs+=variableDefinitionItem (COMMA defs+=variableDefinitionItem)*
    ;

variableDefinitionItem
    : name=L_IDENT (DEF_ASSIGN value=basicExpression)?
    ;

functionDefinition
    : FUN name=L_IDENT OPEN_PARENS params=functionParameters CLOSE_PARENS body=functionBody
    ;

functionParameters
    : (params+=L_IDENT (COMMA params+=L_IDENT)*)?
    ;

functionBody
    : OPEN_BRACE scopeExpression CLOSE_BRACE
    ;

expression
    : (basicExpression SEMICOLON)* basicExpression
    ;

basicExpression
    : assocExpression
    | comparisonExpression
    ;

assocExpression
    : postfixExpression                                                                 #atom
    | operator=OP_NOT expr=assocExpression                                              #unaryExpression
    | operator=MINUS expr=assocExpression                                               #unaryExpression
    | operator=PLUS expr=assocExpression                                                #unaryExpression
    | <assoc=left>  lhs=assocExpression operator=(MUL | DIV | MOD) rhs=assocExpression  #binaryExpression
    | <assoc=left>  lhs=assocExpression operator=(PLUS | MINUS) rhs=assocExpression     #binaryExpression
    // by precedence here was comparison
    | <assoc=left>  lhs=assocExpression operator=OP_AND rhs=assocExpression             #binaryExpression
    | <assoc=left>  lhs=assocExpression operator=OP_OR rhs=assocExpression              #binaryExpression
    | <assoc=right> lhs=assocExpression operator=ASSIGN rhs=assocExpression             #binaryExpression
    ;

comparisonExpression
    : lhs=assocExpression operator=(OP_LT | OP_GT | OP_LE | OP_GE | OP_EQ | OP_NE) rhs=assocExpression
    ;

postfixExpression
    : primary                                                                                       #emptySuffix
    | base=postfixExpression OPEN_PARENS (args=expression (COMMA args=expression)*)? CLOSE_PARENS   #indexExpression
    | base=postfixExpression OPEN_BRACKET index=expression CLOSE_BRACKET                            #callExpression
    ;

primary
    : num=NUMBER_LITERAL                                                                                #numberLiteralExpression
    | booleanLiteral                                                                                    #booleanLiteralExpression
    | STRING_LITERAL                                                                                    #stringLiteral
    | CHARACTER_LITERAL                                                                                 #characterLiteral
    | OPEN_BRACKET (items+=expression (COMMA items+=expression)*)? CLOSE_BRACKET                        #arrayLiteral
    | tag=U_IDENT (OPEN_PARENS (items+=expression (COMMA items+=expression)*)? CLOSE_PARENS)?           #sExp
    | L_IDENT                                                                                           #identifier
    | OPEN_PARENS scopeExpression CLOSE_PARENS                                                          #scope
    | SKIP_                                                                                             #skip
    | FUN OPEN_PARENS args=functionParameters CLOSE_PARENS body=functionBody                            #functionExpression
    | ifThenElse                                                                                        #conditionalExpression
    | caseWhen                                                                                          #caseExpression
    | WHILE expression DO scopeExpression OD                                                            #whileLoop
    | DO scopeExpression WHILE expression OD                                                            #doWhileLoop
    | FOR init=scopeExpression COMMA stop=expression COMMA update=expression DO body=scopeExpression OD #forLoop
    ;

booleanLiteral
    : val=TRUE
    | val=FALSE
    ;

caseWhen
    : CASE expression OF caseBranches ESAC
    ;

caseBranches
    : branches+=caseBranch (BRANCH_SEP branches+=caseBranch)*
    ;

caseBranch
    : pattern ARROW scopeExpression
    ;

pattern
    : OPEN_PARENS pattern CLOSE_PARENS  #parens
    | alias=L_IDENT (AT pattern)?       #aliasedPattern
    | sExpPattern                       #sExpPat
    | arrayPattern                      #arrayPat
    | numberPattern                     #numberPat
    | booleanLiteral                    #booleanPat
    | STRING_LITERAL                    #stringPat
    | CHARACTER_LITERAL                 #charPat
    | PAT_BOX                           #boxTypePat
    | PAT_VAL                           #valTypePat
    | PAT_STR                           #strTypePat
    | PAT_ARRAY                         #arrayTypePat
    | PAT_SEXP                          #sExpTypePat
    | PAT_FUN                           #funTypePat
    | WILDCARD                          #wildcard
    ;

numberPattern
    : num=NUMBER_LITERAL        #positiveNumberPattern
    | MINUS num=NUMBER_LITERAL  #negativeNumberPattern
    ;

sExpPattern
    : tag=U_IDENT (OPEN_PARENS items+=pattern (COMMA items+=pattern)* CLOSE_PARENS)?
    ;

arrayPattern
    : (OPEN_BRACKET items+=pattern (COMMA items+=pattern)* OPEN_BRACKET)?
    ;

ifThenElse
    : IF cond=expression THEN then=scopeExpression elsePart? FI
    ;

elsePart
    : ELIF cond=expression THEN then=scopeExpression elsePart? #elseIf
    | ELSE scopeExpression                                     #else
    ;