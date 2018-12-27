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
import Data.Aeson (Value, FromJSON, encode, object, (.=))
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
  id        :: Text
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
register = "http://localhost:3000/users/register"

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

-- this is VERY BAD
-- i havent managed to solve the type of the output
-- to be m Request
-- thus I cut corner and dumped IO()
-- input: manager, url, token or empty string, body object
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
--    
--    response <- httpLbs fullReq manager
--    putStrLn $ "The status code was: "
--          ++ show (statusCode $ responseStatus response)
--    L8.putStrLn $ responseBody response

-- CLI loop
loopOver :: Manager -> IO()
loopOver manager = do
  hSetBuffering stdin LineBuffering
  input <- Prelude.words <$> getLine --fmap (Prelude.map read.(Prelude.words)) getLine
  putStrLn $ show input
  case input of
    ["cust", "register", username, password] -> do
      let usr = requestUser username password
      req <- buildPOSTRequest register emptyToken usr
      res <- getResponse req manager
      L8.putStrLn $ res
      loopOver manager
    ["cust", "login", username, password] -> do
      let usr = requestUser username password
      req <- buildPOSTRequest login emptyToken usr
      res <- getResponse req manager
      L8.putStrLn $ res
      L8.writeFile tokenPath res
      loopOver manager
    ["cust", "new", name, email, phone] -> do
      let customer = requestCustomer name email phone
      let tkn = readToken tokenPath
      req <- buildPOSTRequest customers tkn customer
      res <- getResponse req manager
      L8.putStrLn $ res
      loopOver manager
    -- this other 2 should be in 
    ["cust", "list"] -> do
      let tkn = readToken tokenPath
      req <- buildGETRequest customers tkn
      res <- getResponse req manager
      L8.putStrLn $ res      
      loopOver manager
    ["cust", "search", str] -> do
      let tkn = readToken tokenPath
      let cSearch = customerSearch str
      req <- buildGETRequest cSearch tkn
      res <- getResponse req manager
      L8.putStrLn $ res
      loopOver manager
    ["quit"] -> do putStrLn "Ok Bye!"
    ["help"] -> do
      showUsage
      loopOver manager

    _ -> do
      putStrLn $ "Invalid command"
      loopOver manager


-- TODO READ TOKEN FROM FILE
-- APPEND IT FOR USER REQUESTS

readToken :: FilePath -> String
readToken = undefined

-- here must parse strings in 1 string, not separate
showUsage :: IO()
showUsage =
  do
    putStrLn "\n\n"
    putStrLn "Commands:"
    putStrLn "\"cust\" \"register\" \"<username>\" \"<password>\""
    putStrLn "\"cust\" \"login\" \"<username>\" \"<password>\""
    putStrLn "\"cust\" \"new\" \"<name>\" \"<email>\" \"<phone>\""
    putStrLn "\"cust\" \"list\""
    putStrLn "\"cust\" \"search\" \"<string>\""
    putStrLn "\"quit\""
    putStrLn "\n\n"


main :: IO ()
main = do
  showUsage
  manager <- newManager tlsManagerSettings
  loopOver manager
  putStrLn $ "Ok Bye."
