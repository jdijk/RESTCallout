global class RESTCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HTTPRequest req)
    {
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('BirthPlace', 'Rotterdam');
        res.setBody('{"first_name":"Jan", "last_name":"Jansen"}');
        res.setStatusCode(200);
        
        return res;
    }

}