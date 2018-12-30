#!/usr/bin/env stack
{- stack
   --resolver lts-12.6
   --install-ghc
   runghc
   --package http-client-tls
   --package filepath
   --package aeson
-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

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
import Control.Monad (forM, liftM)
import Control.Monad.Catch
import Data.Aeson (Value, FromJSON, encode, decode, object, (.=))
import Data.Text

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

register :: String
--  Mikkel perhaps the path to the localhost should be a constant ?
--- if path changes we need to change it many times.
handleSignedRequestsregister = "http://localhost:3000/users/register"

login :: String
login = "http://localhost:3000/users/authenticate"

customers :: String
customers = "http://localhost:3000/customers"

customerSearch :: String -> String
customerSearch src = "http://localhost:3000/customers/" ++ src

tokenPath :: FilePath
tokenPath = "./tmp/.jwt-token"

emptyToken :: String
emptyToken = "whatever"

-- build user request
requestUser :: String -> String -> Value
requestUser uname pwd = object
            [ "username" .= (uname :: String)
            , "password" .= (pwd :: String)
            ]

-- customer request object
requestCustomer :: String -> String -> String -> Value
requestCustomer name email phone = object
                [ "name"  .= (name :: String)
                , "email" .= (email :: String)
                , "phone" .= (phone :: String)
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
handleResponse req manager= do
  res <- getResponse req manager
  L8.putStrLn $ res
  return res

-- token signed and unsigned requests
-- alternatively could sign everything
handleRequests :: Manager -> String -> String -> Maybe Value -> IO BS.ByteString
handleRequests manager url token v = do
  req <- case v of
          Just val -> buildPOSTRequest url token val
          Nothing -> buildGETRequest url token
  res <- handleResponse req manager
  return res

-- MIKKEL ok nice with the handleSignedRequests .. this is actually something like this
-- I was looking for
handleSignedRequests :: Manager -> String -> Maybe Value -> IO BS.ByteString
handleSignedRequests manager url v = do
  tkn <- readToken tokenPath
  res <- handleRequests manager url tkn v
  return res

-- encapsulated user interactions
handleUser :: Manager -> String -> String -> String -> IO BS.ByteString
handleUser manager url name pwd = do
  let usr = requestUser name pwd
  res <- handleRequests manager url emptyToken (Just usr)
  return res

-- CLI loop
loopOver :: Manager -> IO()
loopOver manager = do
  hSetBuffering stdin LineBuffering
  input <- Prelude.words <$> getLine
  putStrLn $ show input
  case input of
    ["cust", "register", username, password] -> do
      handleUser manager register username password
      loopOver manager
    ["cust", "login", username, password] -> do
      res <- handleUser manager login username password
      let tok = decodeToken res
      Prelude.writeFile tokenPath tok
      loopOver manager
    ["cust", "new", name, email, phone] -> do
      let customer = requestCustomer name email phone
      handleSignedRequests manager customers (Just customer)
      loopOver manager
    ["cust", "list"] -> do
      handleSignedRequests manager customers Nothing
      loopOver manager
    ["cust", "search", str] -> do
      let cSearch = customerSearch str
      handleSignedRequests manager cSearch Nothing
      -- MIKKEL perhaps the handleSignedRequests
      -- could call loopOver as well ?
      loopOver manager
    ["quit"] -> do putStrLn "Ok Bye!"
    ["help"] -> do
      showUsage
      loopOver manager
    _ -> do
      putStrLn $ "Invalid command"
      loopOver manager


decodeToken :: BS.ByteString -> String
decodeToken bs = case decode bs of
  Just (UserLogin status msg df) -> decodeData df
  Nothing -> "invalid datafield"

decodeData :: Maybe UserData -> String
decodeData m = case m of
  Just (UserData user token) -> token
  Nothing -> "invalid token"


-- here i do not check if file exists
-- it's bad as it can crash the program
readToken :: FilePath -> IO String
readToken tknPath = Prelude.readFile tknPath

-- alternative: can be read from a README file
showUsage :: IO()
showUsage =
  do
    putStrLn "\n\n\
      \Commands:\n\
      \cust register <username> <password>\n\
      \cust login <username> <password>\n\
      \cust new <name> <email> <phone>\n\
      \cust list\n\
      \cust search <string>\n\
      \quit\n\
      \help\n\
      \\n\n"

main :: IO ()
main = do
  showUsage
  manager <- newManager tlsManagerSettings
  loopOver manager
