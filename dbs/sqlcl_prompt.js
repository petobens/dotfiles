var db = util.executeReturnOneCol(
    'SELECT sys_context(\'userenv\',\'db_name\') FROM dual'
);
sqlcl.setStmt('set sqlprompt "_USER@' + db + '> "');
sqlcl.run();
