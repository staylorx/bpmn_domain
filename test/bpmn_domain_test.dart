import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:test/test.dart';

void main() {
  // =========================================================================
  // Value objects
  // =========================================================================

  group('Given NodeId', () {
    test('Then equality is structural', () {
      expect(
          const NodeId('ProcessOrder'), equals(const NodeId('ProcessOrder')));
      expect(
          const NodeId('ProcessOrder'), isNot(equals(const NodeId('Other'))));
    });

    test('Then isSimpleName rejects qualified names', () {
      expect(const NodeId('ProcessOrder').isSimpleName, isTrue);
      expect(const NodeId('de.monticore.bpmn').isSimpleName, isFalse);
    });

    test('Then toString returns value', () {
      expect(const NodeId('Foo').toString(), 'Foo');
    });
  });

  group('Given QualifiedNodeId', () {
    test('Then parse splits on dots', () {
      final q = QualifiedNodeId.parse(
          'de.monticore.bpmn.examples.OrderToDeliveryWorkflow');
      expect(q.segments.length, 5);
      expect(q.simpleName, 'OrderToDeliveryWorkflow');
      expect(q.qualifier, 'de.monticore.bpmn.examples');
    });

    test('Then toString rejoins segments', () {
      final q = QualifiedNodeId(['de', 'pkg', 'MyProcess']);
      expect(q.toString(), 'de.pkg.MyProcess');
    });
  });

  group('Given PackagePath', () {
    test('Then root is empty', () {
      expect(PackagePath.root.isRoot, isTrue);
      expect(PackagePath.root.toString(), '');
    });

    test('Then parse produces correct segments', () {
      final p = PackagePath.parse('de.monticore.bpmn.examples');
      expect(p.segments, ['de', 'monticore', 'bpmn', 'examples']);
    });

    test('Then qualify prepends package', () {
      final p = PackagePath.parse('de.monticore.bpmn.examples');
      expect(p.qualify('OrderToDeliveryWorkflow'),
          'de.monticore.bpmn.examples.OrderToDeliveryWorkflow');
    });

    test('Then root qualify returns simple name', () {
      expect(PackagePath.root.qualify('Simple'), 'Simple');
    });
  });

  group('Given Stereotype', () {
    test('Then incarnates factory', () {
      final s = Stereotype.incarnates('Research');
      expect(s.key, 'incarnates');
      expect(s.value, 'Research');
      expect(s.toString(), '<<incarnates="Research">>');
    });

    test('Then marker stereotype without value', () {
      const s = Stereotype(key: 'abstract');
      expect(s.toString(), '<<abstract>>');
    });
  });

  group('Given WfModifier', () {
    test('Then none has no stereotypes', () {
      expect(WfModifier.none.stereotypes, isEmpty);
      expect(WfModifier.none.isIncarnation, isFalse);
    });

    test('Then incarnatesTarget is extracted correctly', () {
      final mod = WfModifier(stereotypes: [Stereotype.incarnates('Draft')]);
      expect(mod.isIncarnation, isTrue);
      expect(mod.incarnatesTarget, 'Draft');
    });
  });

  group('Given WfTypeRef', () {
    test('Then equality is structural', () {
      expect(WfTypeRef.string, equals(const WfTypeRef('String')));
      expect(WfTypeRef.named('Order'), equals(WfTypeRef.named('Order')));
    });
  });

  group('Given ImportStatement', () {
    test('Then wildcard toString', () {
      const imp = ImportStatement(
          path: 'de.monticore.bpmn.cds.OrderToDelivery', wildcard: true);
      expect(imp.toString(), 'import de.monticore.bpmn.cds.OrderToDelivery.*;');
    });

    test('Then named import toString', () {
      const imp =
          ImportStatement(path: 'de.monticore.bpmn.cds.OrderToDelivery.Order');
      expect(imp.toString(),
          'import de.monticore.bpmn.cds.OrderToDelivery.Order;');
    });
  });

  // =========================================================================
  // Gateway entities
  // =========================================================================

  group('Given WfGateway', () {
    test('Then splitXor factory', () {
      final g = WfGateway.splitXor('OrderFulfillable');
      expect(g.id, const NodeId('OrderFulfillable'));
      expect(g.direction, GatewayDirection.split);
      expect(g.kind, isA<ExclusiveGateway>());
    });

    test('Then mergeAnd factory', () {
      final g = WfGateway.mergeAnd('MergeWork');
      expect(g.direction, GatewayDirection.merge);
      expect(g.kind, isA<ParallelGateway>());
    });

    test('Then splitReceiveFirst is event-based', () {
      final g = WfGateway.splitReceiveFirst('WaitForResponse');
      expect(g.kind, isA<ExclusiveEventGateway>());
    });

    test('Then complex gateway carries guard expression', () {
      final g = const WfGateway(
        id: NodeId('VoteDecision'),
        direction: GatewayDirection.split,
        kind: ComplexGateway(guard: 'majority(votes) > 0.5'),
      );
      expect((g.kind as ComplexGateway).guard, 'majority(votes) > 0.5');
    });

    test('Then equality is structural', () {
      final a = WfGateway.splitXor('G');
      final b = WfGateway.splitXor('G');
      expect(a, equals(b));
    });
  });

  group('Given WfInlineGateway', () {
    test('Then inline gateway has no id', () {
      const gw = WfInlineGateway(
          direction: GatewayDirection.split, kind: ExclusiveGateway());
      expect(gw.direction, GatewayDirection.split);
    });
  });

  // =========================================================================
  // Event trigger entities
  // =========================================================================

  group('Given EventTrigger', () {
    test('Then CancelTrigger toString', () {
      expect(const CancelTrigger().toString(), 'cancel');
    });

    test('Then CompensateTrigger with activity', () {
      final t = const CompensateTrigger(activity: NodeId('ProcessOrder'));
      expect(t.toString(), 'compensate ProcessOrder');
    });

    test('Then CompensateTrigger async flag', () {
      const t = CompensateTrigger(async: true);
      expect(t.toString(), 'compensate async');
    });

    test('Then ConditionalTrigger', () {
      const t = ConditionalTrigger(condition: 'stock.available > 0');
      expect(t.toString(), 'when [stock.available > 0]');
    });

    test('Then TerminateTrigger', () {
      expect(const TerminateTrigger().toString(), 'terminate');
    });

    test('Then TimerTrigger', () {
      const t = TimerTrigger(condition: 'after PT4H');
      expect(t.toString(), 'timer [after PT4H]');
    });

    test('Then NotificationTrigger message', () {
      final t = const NotificationTrigger(
        kind: NotificationKind.message,
        notificationName: NodeId('cancelMsg'),
      );
      expect(t.toString(), 'message cancelMsg');
    });

    test('Then MultipleTrigger one', () {
      final t = const MultipleTrigger(
        triggers: [CancelTrigger(), TerminateTrigger()],
        parallel: false,
      );
      expect(t.toString(), 'one { cancel, terminate }');
    });

    test('Then MultipleTrigger all is parallel', () {
      final t = const MultipleTrigger(
        triggers: [CancelTrigger()],
        parallel: true,
      );
      expect(t.toString(), 'all { cancel }');
    });
  });

  // =========================================================================
  // WfEvent entity
  // =========================================================================

  group('Given WfEvent', () {
    test('Then start factory creates catching start', () {
      final e = WfEvent.start('ReceiveOrder');
      expect(e.id, const NodeId('ReceiveOrder'));
      expect(e.role, EventRole.start);
      expect(e.direction, EventDirection.catch_);
      expect(e.isStart, isTrue);
      expect(e.isNoneEvent, isTrue);
    });

    test('Then end factory creates throwing end', () {
      final e = WfEvent.end('OrderCompleted');
      expect(e.role, EventRole.end);
      expect(e.direction, EventDirection.throw_);
      expect(e.isEnd, isTrue);
    });

    test('Then terminate end event', () {
      final e = WfEvent.terminate('ProcessAborted');
      expect(e.trigger, isA<TerminateTrigger>());
    });

    test('Then timerCatch event', () {
      final e = WfEvent.timerCatch('DailyReminder', 'every P1D');
      expect(e.isTimer, isTrue);
      expect(e.direction, EventDirection.catch_);
      expect((e.trigger as TimerTrigger).condition, 'every P1D');
    });

    test('Then compensationBoundary event', () {
      final e = WfEvent.compensationBoundary(
        name: 'PossibleCancellation',
        compensatedActivity: 'ProcessOrder',
        handlerActivity: 'RollbackOrderProcessing',
      );
      expect(e.isBoundary, isTrue);
      expect(e.compensationHandler?.compensatedActivity.value, 'ProcessOrder');
      expect(e.compensationHandler?.handlerActivity.value,
          'RollbackOrderProcessing');
    });

    test('Then messageCatchStart', () {
      final e = WfEvent.messageCatchStart('ReceiveOrder', 'orderMsg');
      expect(e.isMessage, isTrue);
      expect(e.isStart, isTrue);
    });

    test('Then errorEnd', () {
      final e = WfEvent.errorEnd('PaymentFailed', 'CardDeclinedError');
      expect(e.isEnd, isTrue);
      final trigger = e.trigger as NotificationTrigger;
      expect(trigger.kind, NotificationKind.error);
    });
  });

  // =========================================================================
  // Activity entities
  // =========================================================================

  group('Given LoopCharacteristic', () {
    test('Then WfStandardLoop while', () {
      final l = WfStandardLoop.whileLoop('retries < 3', max: 5);
      expect(l.isWhile, isTrue);
      expect(l.loopCondition, 'retries < 3');
      expect(l.maxIterations, 5);
      expect(l.toString(), 'while [retries < 3] max 5');
    });

    test('Then WfStandardLoop until', () {
      final l = WfStandardLoop.untilLoop('delivered == true');
      expect(l.isWhile, isFalse);
      expect(l.toString(), 'until [delivered == true]');
    });

    test('Then WfLoopCardinality literal', () {
      final c = WfLoopCardinality.count(5);
      expect(c.literalCount, 5);
      expect(c.toString(), 'count 5');
    });

    test('Then WfLoopCardinality expression', () {
      final c = WfLoopCardinality.expression('order.numberOfOrderedProducts');
      expect(c.expression, 'order.numberOfOrderedProducts');
      expect(c.toString(), 'count [order.numberOfOrderedProducts]');
    });

    test('Then WfLoopCardinality collection', () {
      final c = WfLoopCardinality.collection('orderItems');
      expect(c.collectionName, 'orderItems');
      expect(c.toString(), 'count orderItems');
    });

    test('Then WfMILoop parallel over collection', () {
      final l = WfMILoop.parallelOver('orderItems');
      expect(l.isParallel, isTrue);
      expect(l.cardinality.collectionName, 'orderItems');
    });

    test('Then WfMILoop sequential', () {
      final l = WfMILoop.sequential(3);
      expect(l.isParallel, isFalse);
      expect(l.cardinality.literalCount, 3);
    });
  });

  group('Given WfTask', () {
    test('Then generic task factory', () {
      final t = WfTask.generic('Introduction');
      expect(t.id.value, 'Introduction');
      expect(t.type, TaskType.generic);
      expect(t.hasBoundaryEvents, isFalse);
    });

    test('Then service task factory', () {
      final t = WfTask.service(
        name: 'ProcessOrder',
        webservice: '##webservice',
        operationName: 'processOrderOp',
      );
      expect(t.type, TaskType.service);
      expect(t.taskTypeAttributes?.webservice, '##webservice');
      expect(t.taskTypeAttributes?.operation?.value, 'processOrderOp');
    });

    test('Then manual task with resources', () {
      final t = WfTask.manual('PrepareAndPackProducts', ['order', 'products']);
      expect(t.type, TaskType.manual);
      expect(t.taskTypeAttributes?.resources, ['order', 'products']);
    });

    test('Then send task', () {
      final t = WfTask.send(
        name: 'SendCancellationMessage',
        webservice: '##webservice',
        messageName: 'cancelMsg',
        operationName: 'prepCancelMsg',
      );
      expect(t.type, TaskType.send);
      expect(t.taskTypeAttributes?.message?.value, 'cancelMsg');
    });

    test('Then script task', () {
      final t = WfTask.script(
        name: 'TransformData',
        format: 'JavaScript',
        body: 'return input.trim();',
      );
      expect(t.type, TaskType.script);
      expect(t.taskTypeAttributes?.scriptFormat, 'JavaScript');
    });

    test('Then incarnated task', () {
      final t = WfTask(
        id: const NodeId('LiteratureReview'),
        modifier: WfModifier(stereotypes: [Stereotype.incarnates('Research')]),
      );
      expect(t.isIncarnation, isTrue);
      expect(t.incarnatesTarget, 'Research');
    });

    test('Then service task with MI loop', () {
      final t = WfTask.service(
        name: 'CheckProductAvailability',
        webservice: '##webservice',
        loop: WfMILoop(
          cardinality:
              WfLoopCardinality.expression('order.numberOfOrderedProducts'),
          isParallel: true,
        ),
      );
      expect(t.loop, isA<WfMILoop>());
    });
  });

  group('Given WfSubProcess', () {
    test('Then embedded subprocess', () {
      final sp = WfSubProcess.embedded('ShipOrder');
      expect(sp.subProcessType, SubProcessType.embedded);
      expect(sp.isTransaction, isFalse);
    });

    test('Then transaction subprocess', () {
      final sp = WfSubProcess.transaction('PaymentBlock');
      expect(sp.isTransaction, isTrue);
    });

    test('Then adhoc subprocess', () {
      final sp = WfSubProcess.adhoc(
        'PeerReview',
        completionCondition: 'allReviewed',
        parallel: true,
      );
      expect(sp.isAdHoc, isTrue);
      expect(sp.adHocCharacteristics?.isParallel, isTrue);
      expect(sp.adHocCharacteristics?.completionCondition, 'allReviewed');
    });
  });

  group('Given WfCallActivity', () {
    test('Then simple call activity', () {
      final ca = WfCallActivity.simple(
          name: 'RunDiagnostics', calledProcessName: 'DiagnosticsProcess');
      expect(ca.id.value, 'RunDiagnostics');
      expect(ca.calledElement.value, 'DiagnosticsProcess');
    });
  });

  // =========================================================================
  // Data entities
  // =========================================================================

  group('Given WfIORequirement', () {
    test('Then WfIOSet input', () {
      final s = WfIOSet.inputItem('order', WfTypeRef.named('Order'));
      expect(s.isInput, isTrue);
      expect(s.dataSet.items.first.name.value, 'order');
      expect(s.dataSet.items.first.type?.expression, 'Order');
    });

    test('Then WfIOSet output', () {
      final s = WfIOSet.outputItem('report', WfTypeRef.named('PDF'));
      expect(s.isInput, isFalse);
    });

    test('Then WfIORule', () {
      final rule = WfIORule(
        inputSet: WfDataSet.single(WfDataIO(
            name: const NodeId('order'), type: WfTypeRef.named('Order'))),
        outputSet: WfDataSet.single(const WfDataIO(name: NodeId('invoice'))),
      );
      expect(rule.inputSet.items.first.name.value, 'order');
      expect(rule.outputSet.items.first.name.value, 'invoice');
    });

    test('Then WfDataIO loop flag', () {
      final d = WfDataIO(
          name: const NodeId('items'),
          type: WfTypeRef.named('Product'),
          loop: true);
      expect(d.loop, isTrue);
    });

    test('Then WfDataIO optional and whileExecuting', () {
      final d = const WfDataIO(
          name: NodeId('config'), optional: true, whileExecuting: true);
      expect(d.optional, isTrue);
      expect(d.whileExecuting, isTrue);
    });
  });

  group('Given WfDataObject', () {
    test('Then data factory', () {
      final d = WfDataObject.data('order', 'Order');
      expect(d.kind, DataKind.dataObject);
      expect(d.isDataObject, isTrue);
      expect(d.isDataStore, isFalse);
      expect(d.type.expression, 'Order');
    });

    test('Then store factory', () {
      final d = WfDataObject.store('products', 'Product');
      expect(d.kind, DataKind.dataStore);
      expect(d.isDataStore, isTrue);
    });
  });

  group('Given WfNotification', () {
    test('Then message notification', () {
      final n = WfNotification.message('cancelMsg', WfTypeRef.string);
      expect(n.kind, NotificationKind.message);
      expect(n.isMessage, isTrue);
      expect(n.type, WfTypeRef.string);
    });

    test('Then error notification', () {
      final n = WfNotification.error(
          'CardDeclinedError', WfTypeRef.named('CardError'));
      expect(n.isError, isTrue);
    });

    test('Then signal notification', () {
      final n =
          WfNotification.signal('IncidentResolved', WfTypeRef.named('String'));
      expect(n.isSignal, isTrue);
    });

    test('Then escalation notification', () {
      final n = WfNotification.escalation(
          'SLAWarning', WfTypeRef.named('SLAViolation'));
      expect(n.isEscalation, isTrue);
    });
  });

  group('Given WfOperation', () {
    test('Then request-response operation', () {
      final op = WfOperation.requestResponse(
          name: 'getAddress', input: 'customerID', output: 'address');
      expect(op.hasOutput, isTrue);
      expect(op.outParam?.value, 'address');
    });

    test('Then one-way operation', () {
      final op = WfOperation.oneWay(name: 'sendAlert', input: 'alertMsg');
      expect(op.hasOutput, isFalse);
      expect(op.canThrowErrors, isFalse);
    });

    test('Then operation with thrown errors', () {
      final op = const WfOperation(
        id: NodeId('authorisePayment'),
        inParam: NodeId('paymentRequest'),
        outParam: NodeId('captureConfirmation'),
        thrownErrors: [NodeId('CardDeclinedError')],
      );
      expect(op.canThrowErrors, isTrue);
      expect(op.thrownErrors.first.value, 'CardDeclinedError');
    });
  });

  // =========================================================================
  // Sequence flow entities
  // =========================================================================

  group('Given FlowCondition', () {
    test('Then ExpressionCondition toString', () {
      const c = ExpressionCondition('checker.allProductsAvailable');
      expect(c.toString(), '[checker.allProductsAvailable]');
    });

    test('Then DefaultCondition toString', () {
      expect(const DefaultCondition().toString(), '[_]');
    });
  });

  group('Given FlowTarget', () {
    test('Then element target', () {
      final t = FlowTarget.element(const NodeId('ProcessOrder'));
      expect(t.isElementRef, isTrue);
      expect(t.isGateway, isFalse);
      expect(t.isBlock, isFalse);
      expect(t.hasCondition, isFalse);
    });

    test('Then element target with condition', () {
      final t = FlowTarget.element(
        const NodeId('PrepareAndPackProducts'),
        condition: const ExpressionCondition('checker.allProductsAvailable'),
      );
      expect(t.hasCondition, isTrue);
    });

    test('Then gateway target', () {
      final t = FlowTarget.gateway(
        const WfInlineGateway(
            direction: GatewayDirection.split, kind: ExclusiveGateway()),
      );
      expect(t.isGateway, isTrue);
    });

    test('Then block target', () {
      final t = FlowTarget.block(
        const FlowBlock([]),
      );
      expect(t.isBlock, isTrue);
    });
  });

  group('Given SequenceFlow', () {
    test('Then linear flow factory', () {
      final f =
          SequenceFlow.linear('flow1', ['Start', 'Research', 'Draft', 'Done']);
      expect(f.path.length, 4);
      expect(f.path.first.elementRef?.value, 'Start');
      expect(f.path.last.elementRef?.value, 'Done');
    });
  });

  // =========================================================================
  // Timer conditions
  // =========================================================================

  group('Given TimerCondition', () {
    test('Then AtTimerCondition toString', () {
      const c = AtTimerCondition(TimeOfDay(hours: 9, minutes: 0));
      expect(c.toString(), 'at 09:00');
    });

    test('Then OnDateTimerCondition toString', () {
      const c = OnDateTimerCondition(
          date: CalendarDate(year: 2026, month: 6, day: 30));
      expect(c.toString(), 'on 2026-06-30');
    });

    test('Then OnDateTimerCondition with time', () {
      const c = OnDateTimerCondition(
        date: CalendarDate(year: 2026, month: 6, day: 30),
        atTime: AtTimerCondition(TimeOfDay(hours: 17, minutes: 0)),
      );
      expect(c.toString(), 'on 2026-06-30 at 17:00');
    });

    test('Then AfterPeriodCondition toString', () {
      const c = AfterPeriodCondition('PT4H');
      expect(c.toString(), 'after PT4H');
    });

    test('Then EveryTimeCondition toString', () {
      const c = EveryTimeCondition(period: 'P1W');
      expect(c.toString(), 'every P1W');
    });

    test('Then EveryTimeCondition with times limit', () {
      const c = EveryTimeCondition(period: 'PT1H', times: 24);
      expect(c.toString(), '24 times every PT1H');
    });

    test('Then CronTimerCondition toString', () {
      const c = CronTimerCondition('0 9 * * MON-FRI');
      expect(c.toString(), 'cron "0 9 * * MON-FRI"');
    });
  });

  // =========================================================================
  // Process entities
  // =========================================================================

  group('Given WfLane', () {
    test('Then lane holds elements', () {
      final task = WfTask.generic('ProcessOrder');
      final lane = WfLane(id: const NodeId('Sales'), elements: [task]);
      expect(lane.elements.length, 1);
      expect(lane.elements.first, same(task));
    });
  });

  group('Given WfProcess', () {
    test('Then process with lanes', () {
      final salesLane = WfLane(
        id: const NodeId('Sales'),
        elements: [WfTask.generic('ProcessOrder')],
      );
      final p = WfProcess(
        id: const NodeId('OrderToDeliveryWorkflow'),
        elements: [salesLane],
      );
      expect(p.hasLanes, isTrue);
      expect(p.lanes.length, 1);
      expect(p.lanes.first.id.value, 'Sales');
    });

    test('Then process without lanes', () {
      final p = WfProcess(
        id: const NodeId('SimpleProcess'),
        elements: [WfTask.generic('DoWork')],
      );
      expect(p.hasLanes, isFalse);
    });
  });

  group('Given WorkflowCompilationUnit', () {
    test('Then fully qualified name with package', () {
      final cu = WorkflowCompilationUnit(
        package: PackagePath.parse('de.monticore.bpmn.examples'),
        process: const WfProcess(id: NodeId('OrderToDeliveryWorkflow')),
      );
      expect(cu.fullyQualifiedName,
          'de.monticore.bpmn.examples.OrderToDeliveryWorkflow');
    });

    test('Then fully qualified name without package', () {
      final cu = const WorkflowCompilationUnit(
        process: WfProcess(id: NodeId('Simple')),
      );
      expect(cu.fullyQualifiedName, 'Simple');
    });

    test('Then imports are stored', () {
      final cu = const WorkflowCompilationUnit(
        process: WfProcess(id: NodeId('P')),
        imports: [
          ImportStatement(
              path: 'de.monticore.bpmn.cds.OrderToDelivery', wildcard: true)
        ],
      );
      expect(cu.imports.first.wildcard, isTrue);
    });
  });

  // =========================================================================
  // CD domain entities
  // =========================================================================

  group('Given CdAttribute', () {
    test('Then public attribute', () {
      final a = CdAttribute.public('orderID', 'String');
      expect(a.visibility, CdVisibility.public);
      expect(a.isDerived, isFalse);
      expect(a.toString(), 'public String orderID;');
    });

    test('Then derived attribute', () {
      final a = CdAttribute.derived('workingDays', 'int');
      expect(a.isDerived, isTrue);
      expect(a.toString(), '/int workingDays;');
    });

    test('Then package-local attribute has no visibility keyword', () {
      const a =
          CdAttribute(name: 'hiringDate', type: 'java.time.ZonedDateTime');
      expect(a.visibility, CdVisibility.packageLocal);
      expect(a.toString(), 'java.time.ZonedDateTime hiringDate;');
    });
  });

  group('Given CdMethod', () {
    test('Then public method signature', () {
      final m = const CdMethod(
        name: 'checkAvailability',
        returnType: 'boolean',
        parameters: [
          CdMethodParameter(name: 'productID', type: 'String'),
          CdMethodParameter(name: 'qty', type: 'int'),
        ],
        visibility: CdVisibility.public,
      );
      expect(m.parameters.length, 2);
      expect(m.toString(),
          'public boolean checkAvailability(String productID, int qty);');
    });
  });

  group('Given CdMultiplicity', () {
    test('Then one toString', () {
      expect(CdMultiplicity.one.toString(), '[1]');
    });
    test('Then many toString', () {
      expect(CdMultiplicity.many.toString(), '[*]');
    });
    test('Then optional toString', () {
      expect(CdMultiplicity.optional.toString(), '[0..1]');
    });
    test('Then atLeastOne toString', () {
      expect(CdMultiplicity.atLeastOne.toString(), '[1..*]');
    });
    test('Then range toString', () {
      expect(CdMultiplicity.range(2, 5).toString(), '[2..5]');
    });
  });

  group('Given CdAssociation', () {
    test('Then one-to-many factory', () {
      final a = CdAssociation.oneToMany(
          source: 'LeaveCard', target: 'LeaveEntry', roleName: 'entries');
      expect(a.sourceMultiplicity, CdMultiplicity.one);
      expect(a.targetMultiplicity, CdMultiplicity.many);
      expect(a.roleName, 'entries');
      expect(
          a.toString(), 'association [1] LeaveCard -> entries LeaveEntry [*];');
    });

    test('Then one-to-one factory', () {
      final a = CdAssociation.oneToOne(
          source: 'CustomerDeliveryAgreement', target: 'DestinationAddress');
      expect(a.targetMultiplicity, CdMultiplicity.one);
    });
  });

  group('Given CdClass', () {
    test('Then public data class', () {
      final c = CdClass.publicData('Order', attributes: [
        CdAttribute.public('orderID', 'String'),
        CdAttribute.public('numberOfOrderedProducts', 'int'),
        CdAttribute.public('totalCost', 'double'),
      ]);
      expect(c.visibility, CdVisibility.public);
      expect(c.attributes.length, 3);
      expect(c.isAbstract, isFalse);
    });

    test('Then abstract class', () {
      const c = CdClass(name: 'AbstractProcessor', isAbstract: true);
      expect(c.isAbstract, isTrue);
    });

    test('Then class with superclass and interfaces', () {
      const c = CdClass(
        name: 'SpecialOrder',
        superClass: 'Order',
        interfaces: ['Trackable', 'Auditable'],
      );
      expect(c.superClass, 'Order');
      expect(c.interfaces, contains('Trackable'));
    });
  });

  group('Given CdInterface', () {
    test('Then interface with methods', () {
      final iface = const CdInterface(
        name: 'Trackable',
        methods: [
          CdMethod(
              name: 'getTrackingNumber',
              returnType: 'String',
              visibility: CdVisibility.public),
        ],
      );
      expect(iface.methods.length, 1);
    });
  });

  group('Given CdEnum', () {
    test('Then enum with constants', () {
      const e = CdEnum(
        name: 'PaymentMethod',
        constants: [
          CdEnumConstant('CREDIT_CARD'),
          CdEnumConstant('DEBIT_CARD'),
          CdEnumConstant('BANK_TRANSFER'),
        ],
      );
      expect(e.constants.length, 3);
      expect(e.constants.map((c) => c.name),
          containsAll(['CREDIT_CARD', 'DEBIT_CARD', 'BANK_TRANSFER']));
    });
  });

  group('Given CdClassDiagram — OrderToDelivery', () {
    // Represents the full OrderToDelivery.cd diagram as domain entities
    late CdClassDiagram diagram;

    setUp(() {
      diagram = CdClassDiagram(
        name: 'OrderToDelivery',
        package: PackagePath.parse('de.monticore.bpmn.cds'),
        classifiers: [
          CdClass.publicData('InventoryAvailabilityChecker', attributes: [
            CdAttribute.public('allProductsAvailable', 'boolean'),
            CdAttribute.public('unavailableProducts', 'List<Product>'),
          ]),
          CdClass.publicData('Order', attributes: [
            CdAttribute.public('orderID', 'String'),
            CdAttribute.public('customerID', 'String'),
            CdAttribute.public('numberOfOrderedProducts', 'int'),
            CdAttribute.public('orderList', 'List<Product>'),
            CdAttribute.public('checker', 'InventoryAvailabilityChecker'),
            CdAttribute.public('totalCost', 'double'),
          ]),
          CdClass.publicData('Product', attributes: [
            CdAttribute.public('productID', 'String'),
            CdAttribute.public('name', 'String'),
            CdAttribute.public('orderQuantity', 'int'),
          ]),
          CdClass.publicData('CustomerDeliveryAgreement', attributes: [
            CdAttribute.public('customerID', 'String'),
            CdAttribute.public('isOrderPickedUp', 'boolean'),
            CdAttribute.public('address', 'DestinationAddress'),
          ]),
          CdClass.publicData('DestinationAddress', attributes: [
            CdAttribute.public('street', 'String'),
            CdAttribute.public('houseNumber', 'String'),
            CdAttribute.public('postalCode', 'String'),
            CdAttribute.public('city', 'String'),
          ]),
          CdClass.publicData('PaymentValidityChecker', attributes: [
            CdAttribute.public('paymentValid', 'boolean'),
            CdAttribute.public('cardNumberValid', 'boolean'),
            CdAttribute.public('cardVerificationValueValid', 'boolean'),
            CdAttribute.public('paymentMethod', 'String'),
            CdAttribute.public('cardNumber', 'String'),
            CdAttribute.public('cardVerificationValue', 'String'),
            CdAttribute.public('cardExpirationDate', 'String'),
          ]),
        ],
      );
    });

    test('Then has 6 classes', () {
      expect(diagram.classes.length, 6);
    });

    test('Then findClassifier finds Order', () {
      final c = diagram.findClassifier('Order');
      expect(c, isNotNull);
      expect(c!.name, 'Order');
    });

    test('Then Order has 6 attributes', () {
      final order = diagram.findClassifier('Order') as CdClass;
      expect(order.attributes.length, 6);
    });

    test('Then PaymentValidityChecker has allProductsAvailable-like field', () {
      final pvc = diagram.findClassifier('PaymentValidityChecker') as CdClass;
      final field = pvc.attributes.firstWhere((a) => a.name == 'paymentValid');
      expect(field.type, 'boolean');
    });

    test('Then fullyQualifiedName is correct', () {
      expect(diagram.fullyQualifiedName('Order'),
          'de.monticore.bpmn.cds.OrderToDelivery.Order');
    });
  });

  group('Given CdClassDiagram — Domain (HR)', () {
    late CdClassDiagram diagram;

    setUp(() {
      diagram = CdClassDiagram(
        name: 'Domain',
        package: PackagePath.parse('de.monticore.bpmn.cds'),
        classifiers: [
          const CdClass(
            name: 'Contract',
            attributes: [
              CdAttribute(name: 'hiringDate', type: 'java.time.ZonedDateTime'),
              CdAttribute(
                  name: 'version',
                  type: 'int',
                  visibility: CdVisibility.public),
            ],
          ),
          const CdClass(name: 'DomainUser'),
          CdClass.publicData('Report', attributes: [
            CdAttribute.public('result', 'String'),
            CdAttribute.public('details', 'String'),
          ]),
          const CdClass(name: 'LeaveCard'),
          CdClass(
            name: 'LeaveEntry',
            attributes: [
              const CdAttribute(
                  name: 'startDate', type: 'java.time.ZonedDateTime'),
              const CdAttribute(
                  name: 'endDate', type: 'java.time.ZonedDateTime'),
              CdAttribute.derived('workingDays', 'int'),
              CdAttribute.derived('remainingLeaveDays', 'int'),
              const CdAttribute(name: 'valid', type: 'boolean'),
              const CdAttribute(name: 'approved', type: 'boolean'),
            ],
          ),
          CdClass.publicData('MedicalCertificate', attributes: [
            const CdAttribute(
                name: 'startDate', type: 'java.time.ZonedDateTime'),
            const CdAttribute(name: 'endDate', type: 'java.time.ZonedDateTime'),
            CdAttribute.public('description', 'String'),
          ]),
        ],
        associations: [
          CdAssociation.oneToMany(source: 'DomainUser', target: 'Contract'),
          CdAssociation.oneToMany(
              source: 'LeaveCard', target: 'LeaveEntry', roleName: 'entries'),
          CdAssociation.oneToOne(source: 'LeaveCard', target: 'DomainUser'),
        ],
      );
    });

    test('Then has 6 classifiers', () {
      expect(diagram.classifiers.length, 6);
    });

    test('Then LeaveEntry has derived attributes', () {
      final le = diagram.findClassifier('LeaveEntry') as CdClass;
      final derived = le.attributes.where((a) => a.isDerived).toList();
      expect(derived.length, 2);
      expect(derived.map((a) => a.name),
          containsAll(['workingDays', 'remainingLeaveDays']));
    });

    test('Then has 3 associations', () {
      expect(diagram.associations.length, 3);
    });

    test('Then entries association has role name', () {
      final assoc =
          diagram.associations.firstWhere((a) => a.roleName == 'entries');
      expect(assoc.sourceType, 'LeaveCard');
      expect(assoc.targetType, 'LeaveEntry');
    });
  });

  // =========================================================================
  // Failures
  // =========================================================================

  group('Given WorkflowFailure', () {
    test('Then DeadNode message', () {
      const f = DeadNode(NodeId('OrphanTask'));
      expect(f.message, contains('OrphanTask'));
      expect(f.message, contains('unreachable'));
    });

    test('Then MergeGatewayTooFewIncomingFlows message', () {
      const f = MergeGatewayTooFewIncomingFlows(
          gatewayId: NodeId('MergeWork'), found: 1);
      expect(f.message, contains('MergeWork'));
      expect(f.message, contains('1 incoming'));
    });

    test('Then LackOfSync message', () {
      const f = LackOfSync(NodeId('MergeWork'));
      expect(f.message, contains('MergeWork'));
      expect(f.message, contains('XOR'));
    });

    test('Then ParallelBranchesClosedWithXor message', () {
      const f = ParallelBranchesClosedWithXor(
        mergeGatewayId: NodeId('MergeWork'),
        parallelBranch: [
          NodeId('Introduction'),
          NodeId('MergeWork'),
        ],
      );
      expect(f.message, contains('MergeWork'));
      expect(f.message, contains('XOR'));
    });

    test('Then TaskNotIncarnated message', () {
      const f = TaskNotIncarnated(NodeId('LiteratureReview'));
      expect(f.message, contains('LiteratureReview'));
      expect(f.message, contains('reference model'));
    });

    test('Then UnresolvedNodeReference message', () {
      const f = UnresolvedNodeReference(
        referencedNode: NodeId('MissingNode'),
        fromFlow: NodeId('flow1'),
      );
      expect(f.message, contains('MissingNode'));
      expect(f.message, contains('undefined'));
    });

    test('Then ProcessNotSound message', () {
      const f = ProcessNotSound('path from start cannot reach end event');
      expect(f.message, contains('not sound'));
    });

    test('Then InfiniteLoop message', () {
      const f = InfiniteLoop([NodeId('A'), NodeId('B'), NodeId('A')]);
      expect(f.message, contains('A → B → A'));
    });

    test('Then failures are equatable', () {
      const a = DeadNode(NodeId('X'));
      const b = DeadNode(NodeId('X'));
      const c = DeadNode(NodeId('Y'));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
