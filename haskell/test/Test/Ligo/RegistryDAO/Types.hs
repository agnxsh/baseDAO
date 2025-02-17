-- SPDX-FileCopyrightText: 2021 Tezos Commons
-- SPDX-License-Identifier: LicenseRef-MIT-TC

module Test.Ligo.RegistryDAO.Types
  ( RegistryDaoProposalMetadata (..)
  , TransferProposal (..)
  , ConfigProposal (..)
  , UpdateReceiverParam (..)
  ) where

import Universum

import Lorentz as L

import Ligo.BaseDAO.Common.Types
import Ligo.BaseDAO.Types

-- | Helper type for unpack/pack
data RegistryDaoProposalMetadata
  = Configuration_proposal ConfigProposal
  | Transfer_proposal TransferProposal
  | Update_receivers_proposal UpdateReceiverParam
  | Update_guardian Address
  | Update_contract_delegate (Maybe KeyHash)

instance HasAnnotation RegistryDaoProposalMetadata where
  annOptions = baseDaoAnnOptions

data UpdateReceiverParam
  = Add_receivers [Address]
  | Remove_receivers [Address]

instance HasAnnotation UpdateReceiverParam where
  annOptions = baseDaoAnnOptions


data TransferProposal = TransferProposal
  { tpAgoraPostId  :: Natural
  , tpTransfers    :: [TransferType]
  , tpRegistryDiff :: [(MText, Maybe MText)]
  }

instance HasAnnotation TransferProposal where
  annOptions = baseDaoAnnOptions


data ConfigProposal = ConfigProposal
  { cpFrozenScaleValue :: Maybe Natural
  , cpFrozenExtraValue :: Maybe Natural
  , cpSlashScaleValue :: Maybe Natural
  , cpSlashDivisionValue :: Maybe Natural
  , cpMaxProposalSize :: Maybe Natural
  }

instance HasAnnotation ConfigProposal where
  annOptions = baseDaoAnnOptions

customGeneric "RegistryDaoProposalMetadata" ligoLayout
deriving anyclass instance IsoValue RegistryDaoProposalMetadata

customGeneric "UpdateReceiverParam" ligoLayout
deriving anyclass instance IsoValue UpdateReceiverParam

customGeneric "ConfigProposal" ligoLayout
deriving anyclass instance IsoValue ConfigProposal

customGeneric "TransferProposal" ligoLayout
deriving anyclass instance IsoValue TransferProposal
