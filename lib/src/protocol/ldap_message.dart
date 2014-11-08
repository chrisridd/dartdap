part of ldap_protocol;

/**
 * Envelope for LDAP message protocol exchange
 *
 * See http://tools.ietf.org/html/rfc4511
 *
 *   LDAPMessage ::=
         SEQUENCE {
              messageID      MessageID,
              protocolOp     CHOICE {
                                  bindRequest         BindRequest,
                                  bindResponse        BindResponse,
                                  unbindRequest       UnbindRequest,
                                  searchRequest       SearchRequest,
                                  searchResponse      SearchResponse,
                                  modifyRequest       ModifyRequest,
                                  modifyResponse      ModifyResponse,
                                  addRequest          AddRequest,
                                  addResponse         AddResponse,
                                  delRequest          DelRequest,
                                  delResponse         DelResponse,
                                  modifyRDNRequest    ModifyRDNRequest,
                                  modifyRDNResponse   ModifyRDNResponse,
                                  compareDNRequest    CompareRequest,
                                  compareDNResponse   CompareResponse,
                                  abandonRequest      AbandonRequest
                             }
         }
 *
 *
 */
class LDAPMessage {

  int _messageId;
  int _protocolTag;

  int get protocolTag => _protocolTag;

  ASN1Sequence _protocolOp;
  ASN1Sequence _controls;

  ASN1Object _obj;

  /// return the message id sequence number.
  int get messageId => _messageId;

  /// return the [ASN1Sequence] that makes up this LDAP message
  ASN1Sequence get protocolOp => _protocolOp;

  /// the total length of this encoded message in bytes
  int get messageLength => _obj.totalEncodedByteLength;


  LDAPMessage(this._messageId,RequestOp rop,[List<Control> controls = null]) {
    _protocolTag = rop.protocolOpCode;
    _obj = rop.toASN1();
    if( controls != null && controls.length > 0) {
      _controls = new ASN1Sequence();
      controls.forEach((control) {
        _controls.add( control.toASN1());
        logger.finest("adding control $control");
      });
    }

  }


  LDAPMessage.fromBytes(Uint8List bytes) {
    var o = new ASN1Sequence.fromBytes(bytes);

    if( o  == null || o.elements.length < 2 || o.elements.length > 3) {
      throw new LDAPException("LDAP Message unexpected format. Bytes =${bytes}");
    }


    var i = o.elements[0] as ASN1Integer;
    _messageId = i.intValue;

    _protocolOp = o.elements[1] as ASN1Sequence;

    _protocolTag = _protocolOp.tag;

    // optional - controls....
    if( o.elements.length == 3) {
      _controls = o.elements[3] as ASN1Sequence;
    }


    _obj = o; // save this?
    logger.fine("Got LDAP Message. Id = ${messageId} protocolOp = ${protocolOp}");

  }


  // Convert this LDAP message to a stream of ASN1 encoded bytes
  List<int> toBytes() {

    ASN1Sequence seq = new ASN1Sequence();

    seq.add( new ASN1Integer(_messageId));

    seq.add(_obj);
    if( _controls != null)
      seq.add(_controls);

    var b = seq.encodedBytes;

    var xx = LDAPUtil.toHexString(b);
    logger.finest("LdapMesssage bytes = ${xx}");
    return b;

  }

  String toString() {
    var s = _op2String(_protocolTag);
    return "Msg(id=${_messageId}, op=${s},controls=$_controls)";
  }

}
