xquery version "3.0";

module namespace id = "http://example.com/record/id";

import module namespace util = "http://exist-db.org/xquery/util";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

declare variable $id:ERR-PRESENT := xs:QName("id:ERR-PRESENT");


(:~
: Inserts a unique identifier into a record
:
: @param $record The record to insert an identifier into
:
: @return The record with the identifier or raises
:   the error id:ERR-PRESENT if there is already an
:   identifier in the record
:)
declare
    %test:args("<record><id>existing</id></record>")
        %test:assertError("id:ERR-PRESENT")
    
    %test:args("<record/>")
        %test:assertXPath("$result/exists(id)")
        %test:assertXPath("not($result/empty(id))")
    
    %test:args("<record a='1'><child1>text1</child1></record>")
        %test:assertXPath("$result/exists(id)")
        %test:assertXPath("$result/@a eq '1'")
        %test:assertXPath("local-name(($result/child::element())[1]) eq 'id'")
        %test:assertXPath("local-name(($result/child::element())[2]) eq 'child1'")
        %test:assertXPath("$result/child1/text() eq 'text1'")
function id:insert($record as element(record)) as element(record) {
    
    if($record/id)then
        fn:error($id:ERR-PRESENT, "<id> is already present in record!", $record/id)
    else
        <record>
        {
            $record/@*,
            <id>{id:generate("/db/records")}</id>,
            $record/node()
        }
        </record>
};

declare
    %test:setUp
function id:_test-setup() {
    xmldb:create-collection("/db", "test-records"),
    xmldb:store("/db/test-records", (), <record><id>12345678</id></record>),
    xmldb:store("/db/test-records", (), <record><id>abcdefgh</id></record>)
};

declare
    %test:tearDown
function id:_test-teardown() {
    xmldb:remove("/db/test-records")
};

(:~
: Attempts to generate an id that is not
: already present in a record in the
: records collection
:
: For the record there is much
: that is unsafe about this function.
: It cannot guarantee that even though an id
: is not in-use right now, that it does not generate
: the same id twice. Also a generated id may be used
: before the same generated id can be inserted into
: the database. It would be better to
: replace this function with util:uuid()
: which will generate univerally unique ids.
:
: This function is intentionally dangerous
: to cause the reader to consider the consequences and design
:
: @return An unused id
:)
declare
    %test:args("/db/test-records")
        %test:assertXPath("$result ne '12345678'")
        %test:assertXPath("$result ne 'abcdefgh'")
function id:generate($records-collection as xs:string) as xs:string {
    let $id := id:random()
    return
        if(exists(collection($records-collection)/record/id[. eq $id]))then
            id:generate($records-collection)
        else
            $id
};

(:~
: Generates a random id
: Id's consist of 8 character strings
: of a-z and 0-9
:
: @return A random id
:)
declare function id:random() as xs:string {
    codepoints-to-string(((1 to 8) ! util:random(26)) ! (.[. lt 10] + 48, .[. ge 10] + 87))
};
