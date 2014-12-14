Attribute VB_Name = "Gmail"
' Setup client and authenticator (cached between requests)
Private pGmailClient As RestClient
Private Property Get GmailClient() As RestClient
    If pGmailClient Is Nothing Then
        ' Create client with base url that is appended to all requests
        Set pGmailClient = New RestClient
        pGmailClient.BaseUrl = "https://www.googleapis.com/gmail/v1/"
        
        ' Use the pre-made GoogleAuthenticator found in authenticators/ folder
        ' - Automatically uses Google's OAuth approach including login screen
        ' - Get API client id and secret from https://console.developers.google.com/
        ' - https://github.com/timhall/Excel-REST/wiki/Google-APIs for more info
        Dim Auth As New GoogleAuthenticator
        Auth.Setup CStr(Credentials.Values("Google")("id")), CStr(Credentials.Values("Google")("secret"))
        Auth.AddScope "https://www.googleapis.com/auth/gmail.readonly"
        Auth.Login
        Set pGmailClient.Authenticator = Auth
    End If
    
    Set GmailClient = pGmailClient
End Property

' Load messages for inbox
Function LoadInbox() As Collection
    Set LoadInbox = New Collection
    
    ' Create inbox request with userId and querystring for inbox label
    Dim Request As New RestRequest
    Request.Resource = "users/{userId}/messages"
    Request.AddUrlSegment "userId", "me"
    Request.AddQuerystringParam "q", "label:inbox"
    
    Dim Response As RestResponse
    Set Response = GmailClient.Execute(Request)
    
    If Response.StatusCode = Ok Then
        Dim MessageInfo As Dictionary
        Dim Message As Dictionary
        
        For Each MessageInfo In Response.Data("messages")
            ' Load full messages for each id
            Set Message = LoadMessage(MessageInfo("id"))
            If Not Message Is Nothing Then
                LoadInbox.Add Message
            End If
        Next MessageInfo
    End If
End Function

' Load message details
Function LoadMessage(MessageId As String) As Dictionary
    Dim Request As New RestRequest
    Request.Resource = "users/{userId}/messages/{messageId}"
    Request.AddUrlSegment "userId", "me"
    Request.AddUrlSegment "messageId", MessageId
    
    Dim Response As RestResponse
    Set Response = GmailClient.Execute(Request)
    
    If Response.StatusCode = Ok Then
        Set LoadMessage = New Dictionary
    
        ' Pull out relevant parts of message (from, to, and subject from headers)
        LoadMessage.Add "snippet", Response.Data("snippet")
        
        Dim Header As Dictionary
        For Each Header In Response.Data("payload")("headers")
            Select Case Header("name")
            Case "From"
                LoadMessage.Add "from", Header("value")
            Case "To"
                LoadMessage.Add "to", Header("value")
            Case "Subject"
                LoadMessage.Add "subject", Header("value")
            End Select
        Next Header
    End If
End Function

Sub Test()
    Dim Message As Dictionary
    For Each Message In LoadInbox
        Debug.Print "From: " & Message("from") & ", Subject: " & Message("subject")
        Debug.Print Message("snippet") & vbNewLine
    Next Message
End Sub