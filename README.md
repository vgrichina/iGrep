iGrep – half-assed document indexing for iOS and OS X
====================================================

Overview
--------

iGrep is very simple and hacky solution which allows to index documents and perform full-text search directly on iOS devices. It should support OS X too.

It provides such index implementations:
* `CXSqliteDocumentsIndex` – this is fully implemented and usable implementation based on SQLite DB. However it is quite slow on big amounts of data.
* `CXRawFileIndex` – this implementation stores data in memory mapped file in a custom format. It is incomplete yet, saved index cannot actually be reused for now. However it is quite fast – allows indexing and search for [Enron corpus](http://www.cs.cmu.edu/~enron/) in reasonable time.

It also provides such document tokenizers:
* `CXMailDocument` – parses e-mail messages, i.e. usable with Enron corpus
* `CXHtmlDocument` – parses HTML documents, uses [HTML5 Tidy](https://github.com/w3c/tidy-html5)

It is quite likely that application will need to define own `CXDocument` subclass to index custom data.

Usage
-----

For usage info see demo and tests (in iGrep Xcode project). There is at least one important caveat, before using `CXSqliteDocumentsIndex` you'd better make sure SQLite works well with multiple threads, i.e. do something like:
```objective-c
if (sqlite3_config(SQLITE_CONFIG_SERIALIZED) != SQLITE_OK) {
    NSLog(@"sqlite3_config(SQLITE_CONFIG_SERIALIZED) returns error");
}
```

License
-------

iGrep is available under [MIT license](https://github.com/vgrichina/iGrep/blob/master/LICENSE).
