$(document).on 'turbolinks:load', ->

  mailGraph = $('.mailGraph')

  if mailGraph.length
    data = JSON.parse(mailGraph.attr('data-data'))
    incomingMail = []
    outgoingMail = []
    # Sender25 - Add spam, bounces and held mail to the graph
    spamMail = []
    bouncesMail = []
    heldMail = []
    for d in data
      incomingMail.push(d.incoming)
      outgoingMail.push(d.outgoing)
      # Sender25 - Add spam, bounces and held mail to the graph
      spamMail.push(d.spam)
      bouncesMail.push(d.bounces)
      heldMail.push(d.held)

    # Sender25 - Add labels, spam, bounces and held mail to the graph
    data =
      labels: JSON.parse(mailGraph.attr('data-label'))
      series: [outgoingMail, incomingMail, spamMail, bouncesMail, heldMail]
    options =
      fullWidth: true
      axisY:
        offset:40
      axisX:
        showGrid: false
        offset: 20
        showLabel: true
      height: '230px'
      showArea: true
      high: if incomingMail? && incomingMail.length then undefined else 1000
      chartPadding:
        top:0
        right:30
        bottom:0
        left:0
    # Sender25 - Add responsive options to the graph
    responsive =
      [
        [
          'screen and (min-width: 841px) and (max-width: 1290px)'
          {
            axisX:
             labelInterpolationFnc:
              (value) => return value.slice(3,6)
            chartPadding:
             right:10
          }
        ]
        [
          'screen and (max-width: 840px)'
          {
            showLabel: false
            chartPadding:
             right:0
          }
        ]
      ]

    new Chartist.Line '.mailGraph__graph', data, options, responsive
