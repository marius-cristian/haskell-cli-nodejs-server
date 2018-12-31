#!/usr/bin/env stack
{- stack
   --resolver lts-12.6
   --install-ghc
   runghc
   --package http-client-tls
   --package filepath
   --package aeson
-}
{-# LANGUAGE OverloadedStrings, DeriveGeneric, ScopedTypeVariables #-}

import GHC.Generics
import qualified Data.ByteString.Lazy as BS
import qualified Data.ByteString.Lazy.Char8 as L8
import qualified Data.ByteString.Char8 as C8
import qualified System.Directory as SD
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types.Status  (statusCode)
import System.FilePath
import System.IO
import Data.String ( fromString )
import Control.Monad (forM, liftM, unless, void)
import Control.Monad.Catch
import Data.Aeson (Value, FromJSON, encode, decode, object, (.=))
import Data.Text hiding (words, writeFile, readFile, unlines)
import Data.Maybe

-- data for Json Types
data UserLogin = UserLogin {
  status    :: Int
, message   :: Text
, datafield :: Maybe UserData
} deriving (Show, Generic)
--
data UserData = UserData {
  user :: User
, token :: String
} deriving (Show, Generic)
--
data User = User {
  _id        :: Text
, username  :: Text
} deriving (Show, Generic)

data Customer = Customer {
  name  :: Text
, email :: Text
, phone :: Text
} deriving (Show, Generic)

instance FromJSON UserLogin
instance FromJSON UserData
instance FromJSON User

instance FromJSON Customer

-- constructor for apiEndpoint
apiEndpoint :: String -> String
apiEndpoint = ("http://localhost:3000/" ++)

register :: String
register = apiEndpoint "users/register"

login :: String
login = apiEndpoint "users/authenticate"

customers :: String
customers = apiEndpoint "customers"

customerSearch :: String -> String
customerSearch src =  apiEndpoint ("customers/" ++ src)

tokenPath :: FilePath
tokenPath = "./tmp/.jwt-token"

emptyToken :: String
emptyToken = "whatever"

-- build user request
requestUser :: String -> String -> Value
requestUser uname pwd = object
            [ "username" .= uname
            , "password" .= pwd
            ]

-- customer request object
requestCustomer :: String -> String -> String -> Value
requestCustomer name email phone = object
                [ "name"  .= name
                , "email" .= email
                , "phone" .= phone
                ]

-- input: url, token or empty string, body object
buildPOSTRequest :: (MonadThrow m) => String -> String -> Value -> m Request
buildPOSTRequest url tkn obj =
  do
    req <- parseRequest url
    let fullReq = req {method = "POST"
      , requestBody = RequestBodyLBS $ encode obj
      , requestHeaders =
        [ ("Content-Type", "application/json; charset=utf-8")
        , ("x-access-token", C8.pack tkn)
        ]
      }
    return fullReq


getResponse:: Request -> Manager -> IO BS.ByteString
getResponse req manager = responseBody <$> httpLbs req manager

-- get request in the same manner
buildGETRequest :: (MonadThrow m) => String -> String -> m Request
buildGETRequest url tkn =
  do
    req <- parseRequest url
    let fullReq = req {method = "GET"
      , requestHeaders =
        [("x-access-token", C8.pack tkn)]
      }
    return fullReq

-- treating the response
handleResponse :: Request -> Manager -> IO BS.ByteString
handleResponse req manager= 
  do 
    res <- getResponse req manager
    L8.putStrLn res
    return res

-- token signed and unsigned requests
-- alternatively could sign everything
handleRequests :: Manager -> String -> String -> Maybe Value -> IO BS.ByteString
handleRequests manager url token v = do
  req <- case v of
          Just val -> buildPOSTRequest url token val
          Nothing  -> buildGETRequest url token
  handleResponse req manager

-- MIKKEL ok nice with the handleSignedRequests .. this is actually something like this
-- I was looking for
handleSignedRequests :: Manager -> String -> Maybe Value -> IO BS.ByteString
handleSignedRequests manager url v = do
  tkn <- readToken tokenPath
  handleRequests manager url tkn v

handleSignedRequests_ :: Manager -> String -> Maybe Value -> IO ()
handleSignedRequests_ manager url = void . handleSignedRequests manager url

-- encapsulated user interactions
handleUser :: Manager -> String -> String -> String -> IO BS.ByteString
handleUser manager url name pwd = do
  let usr = requestUser name pwd
  handleRequests manager url emptyToken (Just usr)

handleUser_ :: Manager -> String -> String -> String -> IO ()
handleUser_ manager url name = void . handleUser manager url name


loopOver :: Manager -> IO ()
loopOver manager = do
  hSetBuffering stdin LineBuffering
  input <- words <$> getLine
  putStrLn $ show input
  case input of
    ["cust", "register", username, password] ->
      handleUser_ manager register username password
    ["cust", "login", username, password] -> do
      res <- handleUser manager login username password
      let tok = decodeToken res
      writeFile tokenPath tok
    ["cust", "new", name, email, phone] -> do
      let customer = requestCustomer name email phone
      handleSignedRequests_ manager customers (Just customer)
    ["cust", "list"] ->  
      handleSignedRequests_ manager customers Nothing
    ["cust", "search", str] -> 
      handleSignedRequests_ manager (customerSearch str) Nothing
    ["quit"] -> putStrLn "Ok Bye!"
    ["help"] -> showUsage
    _ -> putStrLn "Invalid command"
  -- much better than a new method see control.monad
  unless (input == ["quit"]) $ loopOver manager


decodeToken :: BS.ByteString -> String
decodeToken bs = case decode bs of
  Just login -> decodeData $ datafield login
  Nothing    -> "invalid datafield"

decodeData :: Maybe UserData -> String
decodeData m = case m of
  Just userData -> token userData
  Nothing       -> "invalid token"

-- fixed with check
readToken :: FilePath -> IO String
readToken path = handle (\(e :: SomeException) -> return "Error reading Token") $ readFile path

-- alternative: can be read from a README file
showUsage :: IO ()
showUsage =
  do
    putStrLn . unlines $ 
      [ "Commands:"
      , "cust register <username> <password>"
      , "cust login <username> <password>"
      , "cust new <name> <email> <phone>"
      , "cust list"
      , "cust search <string>"
      , "quit"
      , "help"
      ]

main :: IO ()
main = do
  showUsage
  manager <- newManager tlsManagerSettings
  loopOver manager