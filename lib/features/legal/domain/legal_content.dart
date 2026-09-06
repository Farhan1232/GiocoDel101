import '../../../core/legal/legal_config.dart';

/// §legal — the in-app Terms & Conditions and Privacy Policy.
///
/// This text was written for THIS application after auditing what it really
/// does (Supabase auth/database, online multiplayer, local preferences, five
/// cosmetic non-consumable purchases verified server-side, no ads and no
/// analytics SDKs). It is original, deliberately conservative wording — not
/// copied from any other company — and it never invents facts: owner
/// identity, contact addresses and governing law come from [LegalConfig] and
/// render as an explicit "to be designated" line until the client provides
/// them (docs/IAP_STORE_SETUP.md). It is a starting point for the owner and
/// their counsel, not legal advice.
///
/// The same substantive text is exported for hosting in
/// `docs/legal/terms-and-conditions.html` and `docs/legal/privacy-policy.html`.
class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

class LegalDocument {
  const LegalDocument({required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;
}

class LegalContent {
  const LegalContent._();

  static String get _entity => LegalConfig.hasEntityName
      ? LegalConfig.entityName
      : '[titolare da designare / owner to be designated]';

  static String _contactIt() => LegalConfig.hasSupportEmail
      ? 'Per assistenza e comunicazioni: ${LegalConfig.supportEmail}.'
      : 'Un indirizzo di contatto per l’assistenza sarà pubblicato dal '
            'titolare prima della distribuzione (in questa versione non è '
            'ancora designato).';

  static String _contactEn() => LegalConfig.hasSupportEmail
      ? 'For support and notices: ${LegalConfig.supportEmail}.'
      : 'A support contact address will be published by the owner before '
            'distribution (not yet designated in this version).';

  static String _privacyContactIt() => LegalConfig.hasPrivacyEmail
      ? 'Per richieste relative ai dati personali: '
            '${LegalConfig.effectivePrivacyEmail}.'
      : 'Un contatto per le richieste sulla privacy sarà pubblicato dal '
            'titolare prima della distribuzione (in questa versione non è '
            'ancora designato).';

  static String _privacyContactEn() => LegalConfig.hasPrivacyEmail
      ? 'For requests concerning personal data: '
            '${LegalConfig.effectivePrivacyEmail}.'
      : 'A privacy contact will be published by the owner before '
            'distribution (not yet designated in this version).';

  static String _lawIt() => LegalConfig.hasCountry
      ? 'Questi termini sono regolati dalla legge di: ${LegalConfig.country}, '
            'fatte salve le norme inderogabili del paese di residenza '
            'dell’utente.'
      : 'La legge applicabile sarà indicata dal titolare prima della '
            'distribuzione; restano comunque salve le norme inderogabili del '
            'paese di residenza dell’utente.';

  static String _lawEn() => LegalConfig.hasCountry
      ? 'These terms are governed by the law of: ${LegalConfig.country}, '
            'without prejudice to mandatory rules of the user’s country of '
            'residence.'
      : 'The governing law will be designated by the owner before '
            'distribution; mandatory rules of the user’s country of '
            'residence remain unaffected in any case.';

  // ---------------------------------------------------------------- terms —

  static LegalDocument terms(String localeCode) =>
      localeCode == 'en' ? _termsEn() : _termsIt();

  static LegalDocument _termsIt() => LegalDocument(
    title: 'Termini e Condizioni',
    sections: [
      LegalSection(
        '1. Il servizio',
        'Gioco del 101 (identificativo Android '
            '`it.giocodel101.gioco_del_101`, identificativo iOS '
            '`it.giocodel101.giocoDel101`) è un gioco di carte napoletane '
            'digitale offerto da $_entity. Comprende partite offline contro il computer, la '
            'modalità Passa e Gioca e partite online multigiocatore (2–4 '
            'giocatori) tramite stanze private e partita rapida. Il gioco '
            'completo — regole, modalità, partite online e offline — è '
            'gratuito.',
      ),
      const LegalSection(
        '2. Account',
        'Per giocare online è necessario un account (registrato con email e '
            'password, oppure ospite). Sei responsabile della custodia delle '
            'tue credenziali e di ciò che avviene tramite il tuo account. Il '
            'nickname scelto è visibile agli altri giocatori: non usare nomi '
            'offensivi, ingannevoli o che violino diritti altrui. Un account '
            'ospite risiede sul dispositivo: se viene disconnesso o il '
            'dispositivo cambia, i suoi progressi possono non essere '
            'recuperabili.',
      ),
      const LegalSection(
        '3. Condotta nelle partite online',
        'Nelle partite online è vietato: usare client modificati o strumenti '
            'automatici, sfruttare errori tecnici, tentare di accedere a dati '
            'di altri giocatori (incluse le carte coperte), molestare altri '
            'utenti o compromettere il funzionamento del servizio. '
            'L’abbandono ripetuto delle partite può comportare la sconfitta '
            'a tavolino secondo le regole del gioco.',
      ),
      const LegalSection(
        '4. Acquisti cosmetici',
        'L’app offre cinque contenuti estetici opzionali (tavoli, un mazzo '
            'alternativo, un dorso, un ornamento del tavolo). Sono acquisti '
            'UNA TANTUM e PERMANENTI (non consumabili): una volta acquistati '
            'restano sbloccati sull’account. Non conferiscono alcun '
            'vantaggio di gioco e non sono necessari per alcuna '
            'funzionalità. Il prezzo mostrato è quello comunicato dallo '
            'store del dispositivo nella tua valuta.',
      ),
      const LegalSection(
        '5. Pagamenti tramite gli store',
        'I pagamenti sono elaborati interamente da Google Play o Apple App '
            'Store secondo i loro termini. Non riceviamo né conserviamo dati '
            'di pagamento (numeri di carta, ecc.). L’acquisto è legato '
            'all’account di gioco con cui è stato effettuato e verificato '
            'sui nostri sistemi prima dello sblocco.',
      ),
      const LegalSection(
        '6. Ripristino degli acquisti',
        'La funzione «Ripristina acquisti» recupera senza alcun costo gli '
            'acquisti già effettuati con lo stesso account dello store, ad '
            'esempio dopo la reinstallazione o il cambio di dispositivo.',
      ),
      const LegalSection(
        '7. Rimborsi',
        'I rimborsi degli acquisti in-app sono gestiti da Google Play o '
            'Apple App Store secondo le rispettive procedure e politiche. '
            'Restano impregiudicati i diritti inderogabili del consumatore '
            'previsti dalla legge applicabile.',
      ),
      const LegalSection(
        '8. Disponibilità del servizio',
        'Le funzioni online dipendono da server e connessioni di terzi e '
            'possono subire interruzioni, manutenzioni o modifiche. Non '
            'garantiamo la disponibilità continua del servizio online. Le '
            'modalità offline restano utilizzabili senza connessione.',
      ),
      const LegalSection(
        '9. Proprietà intellettuale',
        'L’app, la sua grafica, i suoi testi e i suoi contenuti sono '
            'protetti dalle leggi sulla proprietà intellettuale e concessi '
            'in licenza d’uso personale e non commerciale. Le immagini '
            'tradizionali delle carte napoletane utilizzate sono di pubblico '
            'dominio; le rielaborazioni e i contenuti originali dell’app '
            'restano protetti. È vietato copiare, modificare, distribuire o '
            'decompilare l’app oltre i limiti consentiti dalla legge.',
      ),
      const LegalSection(
        '10. Sospensione dell’account',
        'Possiamo sospendere o chiudere un account che violi in modo grave o '
            'ripetuto questi termini (ad esempio per manomissione del client '
            'o abusi verso altri giocatori), ove possibile con preavviso e '
            'motivazione.',
      ),
      const LegalSection(
        '11. Limitazione di responsabilità',
        'Nei limiti consentiti dalla legge, il servizio è fornito «così '
            'com’è» e non rispondiamo dei danni indiretti derivanti '
            'dall’uso o dall’indisponibilità del gioco. Nulla in questi '
            'termini esclude o limita responsabilità che per legge non '
            'possono essere escluse o limitate, né i diritti inderogabili '
            'del consumatore.',
      ),
      const LegalSection(
        '12. Modifiche al servizio e ai termini',
        'Possiamo aggiornare il gioco e questi termini. Le modifiche '
            'rilevanti saranno comunicate nell’app o tramite gli store; la '
            'versione aggiornata indica la data di revisione. L’uso del '
            'servizio dopo l’entrata in vigore delle modifiche ne comporta '
            'l’accettazione.',
      ),
      LegalSection('13. Legge applicabile', _lawIt()),
      LegalSection('14. Contatti', _contactIt()),
    ],
  );

  static LegalDocument _termsEn() => LegalDocument(
    title: 'Terms & Conditions',
    sections: [
      LegalSection(
        '1. The service',
        'Gioco del 101 (Android id `it.giocodel101.gioco_del_101`, iOS id '
            '`it.giocodel101.giocoDel101`) is a digital Neapolitan card '
            'game offered by $_entity. It includes offline play against the computer, Pass & '
            'Play, and online multiplayer (2–4 players) through private '
            'rooms and quick match. The full game — rules, modes, online and '
            'offline play — is free.',
      ),
      const LegalSection(
        '2. Accounts',
        'Playing online requires an account (registered with email and '
            'password, or a guest account). You are responsible for keeping '
            'your credentials safe and for what happens through your '
            'account. Your chosen nickname is visible to other players: do '
            'not use names that are offensive, misleading or infringe '
            'anyone’s rights. A guest account lives on the device: if it is '
            'signed out or the device changes, its progress may not be '
            'recoverable.',
      ),
      const LegalSection(
        '3. Online conduct',
        'In online matches it is forbidden to: use modified clients or '
            'automation tools, exploit technical faults, attempt to access '
            'other players’ data (including hidden cards), harass other '
            'users, or interfere with the operation of the service. '
            'Repeatedly abandoning matches may result in forfeit under the '
            'game rules.',
      ),
      const LegalSection(
        '4. Cosmetic purchases',
        'The app offers five optional cosmetic items (tables, an alternative '
            'deck finish, a card back, a table ornament). They are ONE-TIME, '
            'PERMANENT (non-consumable) purchases: once bought they stay '
            'unlocked on the account. They grant no gameplay advantage and '
            'are not required for any feature. The displayed price is the '
            'one reported by your device’s store in your currency.',
      ),
      const LegalSection(
        '5. Payments through the stores',
        'Payments are processed entirely by Google Play or the Apple App '
            'Store under their terms. We do not receive or store payment '
            'details (card numbers, etc.). A purchase is tied to the game '
            'account that made it and is verified on our systems before the '
            'item unlocks.',
      ),
      const LegalSection(
        '6. Restoring purchases',
        '“Restore purchases” recovers, at no cost, purchases already made '
            'with the same store account — for example after reinstalling '
            'the app or changing device.',
      ),
      const LegalSection(
        '7. Refunds',
        'Refunds of in-app purchases are handled by Google Play or the '
            'Apple App Store under their respective procedures and '
            'policies. Mandatory consumer rights under applicable law are '
            'unaffected.',
      ),
      const LegalSection(
        '8. Service availability',
        'Online features depend on third-party servers and connections and '
            'may be interrupted, maintained or changed. We do not guarantee '
            'continuous availability of the online service. Offline modes '
            'remain usable without a connection.',
      ),
      const LegalSection(
        '9. Intellectual property',
        'The app, its artwork, texts and content are protected by '
            'intellectual-property law and licensed for personal, '
            'non-commercial use. The traditional Neapolitan card images '
            'used are in the public domain; the app’s original content and '
            'adaptations remain protected. Copying, modifying, distributing '
            'or decompiling the app beyond what the law permits is '
            'forbidden.',
      ),
      const LegalSection(
        '10. Account suspension',
        'We may suspend or close an account that seriously or repeatedly '
            'violates these terms (for example client tampering or abuse of '
            'other players), where possible with notice and reasons.',
      ),
      const LegalSection(
        '11. Limitation of liability',
        'To the extent permitted by law, the service is provided “as is” '
            'and we are not liable for indirect damage arising from the use '
            'or unavailability of the game. Nothing in these terms excludes '
            'or limits liability that cannot be excluded or limited by law, '
            'nor mandatory consumer rights.',
      ),
      const LegalSection(
        '12. Changes to the service and terms',
        'We may update the game and these terms. Material changes will be '
            'announced in the app or through the stores; the updated '
            'version shows its revision date. Using the service after '
            'changes take effect constitutes acceptance.',
      ),
      LegalSection('13. Governing law', _lawEn()),
      LegalSection('14. Contact', _contactEn()),
    ],
  );

  // -------------------------------------------------------------- privacy —

  static LegalDocument privacy(String localeCode) =>
      localeCode == 'en' ? _privacyEn() : _privacyIt();

  static LegalDocument _privacyIt() => LegalDocument(
    title: 'Informativa sulla Privacy',
    sections: [
      LegalSection(
        '1. Titolare del trattamento',
        'Questa informativa riguarda l’applicazione «Gioco del 101» '
            '(identificativo Android `it.giocodel101.gioco_del_101`, '
            'identificativo iOS `it.giocodel101.giocoDel101`) e i servizi '
            'online collegati.\n'
            'Titolare del trattamento è $_entity. ${_privacyContactIt()}',
      ),
      const LegalSection(
        '2. Quali dati trattiamo',
        'Trattiamo solo i dati necessari al funzionamento del gioco:\n'
            '• Dati dell’account: indirizzo email (per gli account '
            'registrati), password in forma protetta gestita dal fornitore '
            'di autenticazione, nickname e avatar scelti. Un account ospite '
            'non richiede email.\n'
            '• Dati di gioco online: stanze, partite, mosse, risultati, '
            'punti esperienza, obiettivi, missioni, posizione in '
            'classifica, reazioni al tavolo e segnali tecnici di presenza '
            '(ad esempio la riconnessione).\n'
            '• Dati sugli acquisti: piattaforma (Google/Apple), prodotto '
            'acquistato, identificativi di transazione dello store e stato '
            'dello sblocco. NON riceviamo mai numeri di carta o altri dati '
            'di pagamento.\n'
            '• Registri tecnici: log di sicurezza e di errore lato server, '
            'conservati per un periodo limitato.\n'
            '• Dati locali sul dispositivo: preferenze (lingua, audio, '
            'tema), statistiche offline e partite salvate restano sul tuo '
            'dispositivo e non vengono trasmessi.',
      ),
      const LegalSection(
        '3. Perché li trattiamo',
        'I dati servono a: fornire le partite online e la sincronizzazione '
            'fra dispositivi; far funzionare classifiche, obiettivi e '
            'missioni; verificare gli acquisti e mantenere gli sblocchi; '
            'garantire la sicurezza e prevenire abusi; adempiere ad '
            'obblighi di legge. Non usiamo i dati per pubblicità e non li '
            'vendiamo.',
      ),
      const LegalSection(
        '4. Nessuna pubblicità, nessuna analisi commerciale',
        'Questa versione dell’app non contiene SDK pubblicitari, di '
            'analytics o di profilazione. Se in futuro venissero aggiunti, '
            'questa informativa sarà aggiornata prima della loro '
            'attivazione.',
      ),
      const LegalSection(
        '5. Con chi condividiamo i dati',
        'Ci avvaliamo di fornitori che trattano i dati per nostro conto:\n'
            '• Supabase — autenticazione, database e funzioni server del '
            'gioco.\n'
            '• Google Play (Google) — distribuzione dell’app e pagamenti '
            'su Android.\n'
            '• Apple App Store (Apple) — distribuzione dell’app e '
            'pagamenti su iOS.\n'
            'Ogni fornitore tratta i dati secondo le proprie condizioni e '
            'informative. Il tuo nickname, livello e risultati sono '
            'visibili agli altri giocatori nelle partite e in classifica.',
      ),
      const LegalSection(
        '6. Conservazione',
        'I dati dell’account restano finché l’account esiste. I dati delle '
            'partite sono conservati per il funzionamento del servizio; '
            'alcune ricevute tecniche di partita vengono eliminate '
            'automaticamente dopo pochi giorni. Le registrazioni degli '
            'acquisti sono conservate finché servono a mantenere gli '
            'sblocchi e ad adempiere agli obblighi contabili e di legge.',
      ),
      const LegalSection(
        '7. Sicurezza',
        'Le partite online sono governate dal server: le carte coperte '
            'degli altri giocatori non vengono mai inviate al tuo '
            'dispositivo. L’accesso ai dati è protetto da autenticazione e '
            'da regole di accesso per riga (RLS); gli sblocchi degli '
            'acquisti avvengono solo dopo verifica presso lo store.',
      ),
      const LegalSection(
        '8. I tuoi diritti',
        'Nei limiti previsti dalla legge applicabile (per gli utenti '
            'nell’Unione Europea, il Regolamento (UE) 2016/679 – GDPR), '
            'puoi chiedere l’accesso, la rettifica, la cancellazione, la '
            'limitazione e la portabilità dei tuoi dati, oppure opporti al '
            'trattamento, e proporre reclamo all’autorità di controllo '
            'competente. Per esercitare i diritti, incluso eliminare '
            'l’account e i dati collegati, usa il contatto indicato in '
            'questa informativa.',
      ),
      LegalSection(
        '9. Come eliminare l’account e i dati',
        'Puoi eliminare l’account direttamente nell’app: Impostazioni → '
            'ACCOUNT → «Elimina account». La cancellazione è immediata. '
            'In alternativa scrivi dall’indirizzo email dell’account, o '
            'indicando il nickname per un account ospite, al contatto '
            'privacy riportato al punto 13: in quel caso procediamo entro '
            '30 giorni. Vengono eliminati: account e credenziali, nickname e avatar, '
            'statistiche online, obiettivi, missioni e posizione in '
            'classifica, le partite collegate al tuo account e le '
            'registrazioni degli acquisti che conserviamo. Gli acquisti '
            'non vanno persi: il venditore resta Google Play o l’App '
            'Store, quindi «Ripristina acquisti» li recupera su un nuovo '
            'account. Restano solo i log tecnici di sicurezza, per il loro '
            'breve periodo di conservazione. '
            'I dati che non lasciano mai il dispositivo — preferenze, '
            'statistiche offline, partite salvate — si eliminano '
            'disinstallando l’app o cancellando i suoi dati dalle '
            'impostazioni del telefono.',
      ),
      const LegalSection(
        '10. Minori',
        'Il gioco è un passatempo di carte adatto a un pubblico generale e '
            'non è rivolto specificamente ai bambini. Gli acquisti '
            'richiedono l’account dello store del dispositivo, i cui '
            'strumenti di controllo parentale (approvazione degli acquisti, '
            'limiti di spesa) restano validi.',
      ),
      const LegalSection(
        '11. Trasferimenti internazionali',
        'I server dei fornitori possono trovarsi in paesi diversi dal tuo. '
            'In tal caso il trasferimento avviene con le garanzie previste '
            'dalla normativa applicabile (ad esempio clausole contrattuali '
            'standard).',
      ),
      const LegalSection(
        '12. Modifiche a questa informativa',
        'Aggiorneremo questa informativa quando cambia il modo in cui '
            'trattiamo i dati. La versione in vigore è sempre disponibile '
            'nell’app con la sua data di aggiornamento.',
      ),
      LegalSection('13. Contatti', _privacyContactIt()),
    ],
  );

  static LegalDocument _privacyEn() => LegalDocument(
    title: 'Privacy Policy',
    sections: [
      LegalSection(
        '1. Data controller',
        'This policy covers the application “Gioco del 101” (Android id '
            '`it.giocodel101.gioco_del_101`, iOS id '
            '`it.giocodel101.giocoDel101`) and its online services.\n'
            'The data controller is $_entity. ${_privacyContactEn()}',
      ),
      const LegalSection(
        '2. What data we process',
        'We process only the data the game needs to work:\n'
            '• Account data: email address (for registered accounts), '
            'password in protected form handled by the authentication '
            'provider, chosen nickname and avatar. A guest account needs no '
            'email.\n'
            '• Online play data: rooms, matches, moves, results, experience '
            'points, achievements, missions, leaderboard position, table '
            'reactions and technical presence signals (for example '
            'reconnection).\n'
            '• Purchase data: platform (Google/Apple), purchased product, '
            'store transaction identifiers and unlock status. We NEVER '
            'receive card numbers or other payment details.\n'
            '• Technical logs: server-side security and error logs, kept '
            'for a limited period.\n'
            '• Local device data: preferences (language, audio, theme), '
            'offline statistics and saved games stay on your device and '
            'are not transmitted.',
      ),
      const LegalSection(
        '3. Why we process it',
        'The data serves to: provide online matches and cross-device sync; '
            'run leaderboards, achievements and missions; verify purchases '
            'and keep items unlocked; ensure security and prevent abuse; '
            'and meet legal obligations. We do not use the data for '
            'advertising and we do not sell it.',
      ),
      const LegalSection(
        '4. No advertising, no commercial analytics',
        'This version of the app contains no advertising, analytics or '
            'profiling SDKs. If any are added in the future, this policy '
            'will be updated before they are enabled.',
      ),
      const LegalSection(
        '5. Who we share data with',
        'We rely on providers that process data on our behalf:\n'
            '• Supabase — authentication, database and the game’s server '
            'functions.\n'
            '• Google Play (Google) — app distribution and payments on '
            'Android.\n'
            '• Apple App Store (Apple) — app distribution and payments on '
            'iOS.\n'
            'Each provider processes data under its own terms and '
            'policies. Your nickname, level and results are visible to '
            'other players in matches and on leaderboards.',
      ),
      const LegalSection(
        '6. Retention',
        'Account data is kept for as long as the account exists. Match '
            'data is kept for the operation of the service; some technical '
            'match receipts are deleted automatically after a few days. '
            'Purchase records are kept for as long as needed to maintain '
            'unlocks and to meet accounting and legal obligations.',
      ),
      const LegalSection(
        '7. Security',
        'Online matches are governed by the server: other players’ hidden '
            'cards are never sent to your device. Data access is protected '
            'by authentication and row-level access rules (RLS); purchase '
            'unlocks happen only after verification with the store.',
      ),
      const LegalSection(
        '8. Your rights',
        'Within the limits of applicable law (for users in the European '
            'Union, Regulation (EU) 2016/679 – GDPR), you may request '
            'access to, rectification, erasure, restriction and '
            'portability of your data, object to processing, and lodge a '
            'complaint with the competent supervisory authority. To '
            'exercise these rights — including deleting your account and '
            'its data — use the contact given in this policy.',
      ),
      LegalSection(
        '9. Deleting your account and your data',
        'You can delete your account from inside the app: Settings → '
            'ACCOUNT → “Delete account”. It takes effect immediately. You '
            'can instead write to the privacy contact in section 13 from '
            'the account’s email address, or quoting the nickname for a '
            'guest account, and we act within 30 days. What is erased: the account and its '
            'credentials, nickname and avatar, online statistics, '
            'achievements, missions and leaderboard position, the '
            'matches tied to your account, and the purchase records we '
            'hold. The purchases themselves are not lost: Google Play or '
            'the App Store remains the seller, so “Restore purchases” '
            'recovers them on a new account. Only technical security logs '
            'remain, for their short retention period. '
            'Data that never leaves the device — preferences, offline '
            'statistics, saved games — is removed by uninstalling the app '
            'or clearing its data in the phone’s settings.',
      ),
      const LegalSection(
        '10. Children',
        'The game is a card pastime for a general audience and is not '
            'directed specifically at children. Purchases require the '
            'device store account, whose parental controls (purchase '
            'approval, spending limits) continue to apply.',
      ),
      const LegalSection(
        '11. International transfers',
        'Provider servers may be located in countries other than yours. '
            'Where that happens, transfers rely on the safeguards provided '
            'by applicable law (for example standard contractual clauses).',
      ),
      const LegalSection(
        '12. Changes to this policy',
        'We will update this policy whenever the way we process data '
            'changes. The current version is always available in the app '
            'with its update date.',
      ),
      LegalSection('13. Contact', _privacyContactEn()),
    ],
  );
}
